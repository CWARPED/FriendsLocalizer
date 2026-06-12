import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../crypto/identity.dart';
import '../crypto/group.dart';
import '../app/fixed_location.dart';
import '../app/geolocator_location_provider.dart';
import '../app/location_service.dart';
import '../app/member.dart';
import '../app/onboarding.dart';
import '../app/sensors.dart';
import '../mesh/config.dart';
import '../mesh/mesh_node.dart';
import '../mesh/real_scheduler.dart';
import '../net/server_gateway_transport.dart';
import '../net/directory_client.dart';
import '../net/url.dart';
import 'app_repository.dart';
import 'store.dart';

/// Dépôt réel : vraie crypto (Plan 1) + persistance via [Store].
/// Construire avec [RealRepository.load] (hydrate l'état depuis le store).
class RealRepository extends AppRepository {
  final Store _store;

  Identity? _identity;
  String _identityName = '';
  AppSettings _settings = const AppSettings(serverUrl: 'ws://127.0.0.1:8080');

  final List<_StoredGroup> _groups = [];
  static const _kGroups = 'groups.json';
  static const _kSettings = 'settings.json';

  // --- Moteur de localisation (Task 4) ---
  ServerGatewayTransport? _transport;
  MeshNode? _node; // kept alive until dispose
  LocationService? _location;
  DirectoryClient? _directory;
  FixedLocationProvider? _fixed;
  LocationProvider? _locationProvider; // GPS sur mobile, fixe sur desktop
  final Map<String, LocatedPosition> _located = {};
  final _random = Random.secure();

  RealRepository._(this._store);

  static const _kIdentityBytes = 'identity.bytes';
  static const _kIdentityName = 'identity.name';

  static Future<RealRepository> load(Store store) async {
    final repo = RealRepository._(store);
    await repo._hydrate();
    return repo;
  }

  Future<void> _hydrate() async {
    // Identité
    try {
      final idB64 = _store.getString(_kIdentityBytes);
      if (idB64 != null) {
        _identity = await Identity.fromBytes(base64.decode(idB64));
        _identityName = _store.getString(_kIdentityName) ?? '';
      }
    } catch (_) {
      _identity = null; // identité corrompue -> ré-onboarding
    }

    // Groupes
    try {
      final gJson = _store.getString(_kGroups);
      if (gJson != null) {
        final list = json.decode(gJson) as List;
        _groups
          ..clear()
          ..addAll(list.map((e) => _StoredGroup.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      _groups.clear(); // sauvegarde corrompue -> repli sur vide
    }

    // Réglages
    try {
      final sJson = _store.getString(_kSettings);
      if (sJson != null) {
        final m = json.decode(sJson) as Map<String, dynamic>;
        _settings = AppSettings(
          serverUrl: m['serverUrl'] as String? ?? '',
          internetEnabled: m['internet'] as bool? ?? true,
          bluetoothEnabled: m['bluetooth'] as bool? ?? true,
          myLat: (m['lat'] as num?)?.toDouble() ?? 0,
          myLon: (m['lon'] as num?)?.toDouble() ?? 0,
          themeMode: _parseThemeChoice(m['theme']),
        );
      }
    } catch (_) {
      // réglages par défaut conservés
    }
  }

  @override
  AppIdentity? get identity => _identity == null
      ? null
      : AppIdentity(_identityName, memberId(_identity!.signPublicKey));

  @override
  Future<void> createIdentity(String name) async {
    final id = await Identity.generate();
    _identity = id;
    _identityName = name;
    await _store.setString(_kIdentityBytes, base64.encode(id.toBytes()));
    await _store.setString(_kIdentityName, name);
    notifyListeners();
  }

  // --- Groupes (Task 3) ---
  @override
  List<GroupSummary> get groups => _groups
      .map((g) => GroupSummary(g.id, g.name, g.roster.length))
      .toList(growable: false);

  @override
  List<GroupMember> members(String groupId) {
    final g = _groupById(groupId);
    if (g == null) return const [];
    return g.roster
        .map((m) => GroupMember(memberId(base64.decode(m.pubB64)), m.name))
        .toList(growable: false);
  }

  @override
  Future<GroupSummary> createGroup(String name) async {
    final me = _identity;
    final group = await Group.create('g${DateTime.now().microsecondsSinceEpoch}');
    final roster = <_StoredMember>[
      if (me != null)
        _StoredMember(_identityName, base64.encode(me.signPublicKey)),
    ];
    final stored = _StoredGroup(group.groupId, name,
        base64.encode(group.groupSecret), roster);
    _groups.add(stored);
    await _persistGroups();
    notifyListeners();
    unawaited(refreshGroups()); // s'inscrit tout de suite sur l'annuaire
    return GroupSummary(stored.id, stored.name, stored.roster.length);
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    await _persistGroups();
    notifyListeners();
  }

  @override
  String inviteFor(String groupId) {
    final g = _groupById(groupId);
    final me = _identity;
    return GroupInvite(
      groupId: groupId,
      groupName: g?.name ?? '',
      groupSecret: g == null ? Uint8List(32) : base64.decode(g.secretB64),
      creatorName: _identityName,
      creatorSignPublicKey: me?.signPublicKey ?? Uint8List(32),
    ).encode();
  }

  @override
  Future<void> joinFromInvite(String payload) async {
    final invite = GroupInvite.decode(payload);
    if (_groupById(invite.groupId) != null) return; // idempotent
    final me = _identity;
    final roster = <_StoredMember>[
      _StoredMember(invite.creatorName,
          base64.encode(invite.creatorSignPublicKey)),
      if (me != null)
        _StoredMember(_identityName, base64.encode(me.signPublicKey)),
    ];
    final name = invite.groupName.isEmpty ? invite.groupId : invite.groupName;
    _groups.add(_StoredGroup(invite.groupId, name,
        base64.encode(invite.groupSecret), roster));
    await _persistGroups();
    notifyListeners();
    unawaited(refreshGroups()); // publie ma jointure sur l'annuaire sans attendre
  }

  AppThemeChoice _parseThemeChoice(Object? v) {
    if (v is String) {
      for (final c in AppThemeChoice.values) {
        if (c.name == v) return c;
      }
    }
    return AppThemeChoice.auto;
  }

  _StoredGroup? _groupById(String id) {
    for (final g in _groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<void> _persistGroups() async {
    await _store.setString(
        _kGroups, json.encode(_groups.map((g) => g.toJson()).toList()));
  }

  // --- Réglages (Task 4) ---
  @override
  AppSettings get settings => _settings;
  @override
  void updateSettings(AppSettings settings) {
    final urlChanged = settings.serverUrl != _settings.serverUrl;
    _settings = settings;
    _store.setString(
        _kSettings,
        json.encode({
          'serverUrl': settings.serverUrl,
          'internet': settings.internetEnabled,
          'bluetooth': settings.bluetoothEnabled,
          'lat': settings.myLat,
          'lon': settings.myLon,
          'theme': settings.themeMode.name,
        }));
    // Changer l'adresse du relais coupe la session en cours pour qu'elle se
    // reconstruise sur le NOUVEAU serveur au prochain ensureConnected /
    // refreshGroups — sans avoir à redémarrer l'app.
    if (urlChanged && _transport != null) {
      _transport?.stop();
      _transport = null;
      _node = null;
      _location = null;
      _directory = null;
      _fixed = null;
      _locationProvider = null;
      _located.clear();
    }
    notifyListeners();
  }

  // --- Localisation (Task 4) ---

  /// Construit un [Group] crypto à partir du stockage local.
  Group _cryptoGroup(_StoredGroup g) => Group(
        g.id,
        base64.decode(g.secretB64),
        g.roster
            .map((m) => Member(m.name, base64.decode(m.pubB64)))
            .toList(),
      );

  @override
  GeoPoint get myPosition => GeoPoint(_settings.myLat, _settings.myLon);

  @override
  Future<GeoPoint> currentPosition() async {
    final fix = await _locationProvider?.current();
    return fix?.point ?? myPosition;
  }

  @override
  Stream<GeoPoint> positionUpdates() {
    final p = _locationProvider;
    if (p is GeolocatorLocationProvider) {
      return p.stream().map((f) => f.point);
    }
    return const Stream.empty(); // desktop/test : pas de flux GPS
  }

  /// Publie mon entrée et fusionne le roster de l'annuaire dans la liste
  /// AFFICHÉE/persistée, pour chaque groupe stocké. Indépendant du moteur mesh
  /// (fonctionne donc aussi pour un groupe créé/rejoint après la 1re connexion).
  /// Renvoie true si la liste a changé. Tolérant au hors-ligne (try/catch).
  Future<bool> _pullRoster(DirectoryClient dir) async {
    final me = _identity;
    if (me == null) return false;
    final myId = memberId(me.signPublicKey);
    final myPubB64 = base64.encode(me.signPublicKey);
    var changed = false;
    for (final g in _groups) {
      try {
        await dir.publish(DirectoryEntry(
          groupId: g.id,
          memberId: myId,
          name: _identityName,
          signPublicKeyB64: myPubB64,
        ));
        final entries = await dir.roster(g.id);
        final known = g.roster.map((m) => m.pubB64).toSet();
        for (final e in entries) {
          if (known.add(e.signPublicKeyB64)) {
            g.roster.add(_StoredMember(e.name, e.signPublicKeyB64));
            changed = true;
          }
        }
      } catch (_) {
        // serveur indisponible : on garde le compte actuel, pas d'erreur UI.
      }
    }
    return changed;
  }

  @override
  Future<void> refreshGroups() async {
    if (_identity == null || _groups.isEmpty) return;
    final dir =
        _directory ??= DirectoryClient(directoryBaseFromWs(_settings.serverUrl));
    if (await _pullRoster(dir)) {
      await _persistGroups();
      notifyListeners();
    }
  }

  /// Établit la connexion au relais et synchronise les clés (idempotent).
  ///
  /// Limite connue : le moteur est construit avec les groupes présents au
  /// PREMIER appel ; un groupe créé/rejoint ensuite n'est pas pris en compte
  /// tant que la session n'est pas recréée (à traiter dans un plan ultérieur).
  @override
  Future<void> ensureConnected() async {
    final me = _identity;
    if (me == null) return;
    if (_transport == null) {
      final cryptoGroups = _groups.map(_cryptoGroup).toList();
      // Mobile → vrai GPS ; desktop/test → position manuelle (qu'on garde la
      // main de mettre à jour via _fixed).
      final locationProvider =
          defaultLocationProvider(manualFallback: myPosition);
      if (locationProvider is FixedLocationProvider) {
        _fixed = locationProvider;
      }
      _locationProvider = locationProvider;
      final transport = ServerGatewayTransport(relayWsUrl(_settings.serverUrl));
      // _node is assigned before location uses broadcast, so the late
      // initialisation is safe; the field also keeps the node alive.
      final location = LocationService(
        identity: me,
        myId: memberId(me.signPublicKey),
        groups: cryptoGroups,
        location: locationProvider,
        random: _random,
        nowMs: () => DateTime.now().millisecondsSinceEpoch,
        broadcast: (frame) => _node!.broadcastSealed(frame),
      );
      location.onLocated = (p) {
        _located[p.responderId] = p;
        notifyListeners();
      };
      _node = MeshNode(
        scheduler: RealScheduler(),
        transport: transport,
        config: const MeshConfig(seenTtlMs: 60000),
        random: _random,
        onDeliver: (frame) => location.handleIncoming(frame),
        bindInbound: (handleFrame, handleNeighbor) {
          transport.onFrame = handleFrame;
          transport.onNeighbor = handleNeighbor;
        },
      );
      _transport = transport;
      _location = location;
      _directory = DirectoryClient(directoryBaseFromWs(_settings.serverUrl));
      await transport.start();
    } else {
      _fixed?.point = myPosition; // null sur mobile (GPS) : rien à mettre à jour
      // Reconnexion si la connexion est tombée (utile au mode festival).
      if (!_transport!.isConnected) {
        try {
          await _transport!.start();
        } catch (_) {
          // relais injoignable : on retentera au prochain appel
        }
      }
    }
    final dir = _directory!;
    final myId = memberId(me.signPublicKey);
    for (final cg in _location!.groups) {
      await dir.publish(DirectoryEntry(
        groupId: cg.groupId,
        memberId: myId,
        name: _identityName,
        signPublicKeyB64: base64.encode(me.signPublicKey),
      ));
    }
    var rosterChanged = false;
    for (final cg in _location!.groups) {
      final entries = await dir.roster(cg.groupId);
      for (final e in entries) {
        final pub = base64.decode(e.signPublicKeyB64);
        if (!cg.isMember(pub)) cg.members.add(Member(e.name, pub));
      }
      // Refléter le roster de l'annuaire dans la liste AFFICHÉE (et persistée),
      // pour que chacun voie tous les membres du groupe — pas seulement les
      // siens. Dédup par clé publique.
      final stored = _groupById(cg.groupId);
      if (stored != null) {
        final known = stored.roster.map((m) => m.pubB64).toSet();
        for (final e in entries) {
          if (known.add(e.signPublicKeyB64)) {
            stored.roster.add(_StoredMember(e.name, e.signPublicKeyB64));
            rosterChanged = true;
          }
        }
      }
    }
    if (rosterChanged) {
      await _persistGroups();
      notifyListeners();
    }
  }

  @override
  Future<void> requestLocation({
    required String groupId,
    required String targetId,
    bool live = false,
  }) async {
    await _location?.requestLocation(
        groupId: groupId, targetId: targetId, live: live);
  }

  @override
  LocatedPosition? located(String responderId) => _located[responderId];

  @override
  Future<void> dispose() async {
    await _transport?.stop();
    _node = null;
    super.dispose();
  }
}

class _StoredMember {
  final String name;
  final String pubB64;
  const _StoredMember(this.name, this.pubB64);
  Map<String, dynamic> toJson() => {'name': name, 'pub': pubB64};
  factory _StoredMember.fromJson(Map<String, dynamic> j) =>
      _StoredMember(j['name'] as String, j['pub'] as String);
}

class _StoredGroup {
  final String id;
  final String name;
  final String secretB64;
  final List<_StoredMember> roster;
  const _StoredGroup(this.id, this.name, this.secretB64, this.roster);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'secret': secretB64,
        'roster': roster.map((m) => m.toJson()).toList(),
      };
  factory _StoredGroup.fromJson(Map<String, dynamic> j) => _StoredGroup(
        j['id'] as String,
        j['name'] as String,
        j['secret'] as String,
        (j['roster'] as List)
            .map((e) => _StoredMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
