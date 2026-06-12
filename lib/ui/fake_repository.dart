import 'dart:convert';
import 'dart:typed_data';
import 'app_repository.dart';
import '../app/member.dart';
import '../app/onboarding.dart';

/// Implémentation en mémoire pour le dev/test (aucune crypto/réseau réels).
class FakeRepository extends AppRepository {
  AppIdentity? _identity;
  final List<GroupSummary> _groups = [];
  final Map<String, List<GroupMember>> _members = {};
  final Map<String, Uint8List> _groupSecret = {};
  AppSettings _settings = const AppSettings(serverUrl: 'ws://127.0.0.1:8080');
  final Map<String, LocatedPosition> _located = {};
  int _seq = 0;

  @override
  AppIdentity? get identity => _identity;

  @override
  Future<void> createIdentity(String name) async {
    final bytes = Uint8List(32);
    final n = utf8.encode(name);
    for (var i = 0; i < 32; i++) {
      bytes[i] = n.isEmpty ? i : n[i % n.length] ^ i;
    }
    _identity = AppIdentity(name, memberId(bytes));
    notifyListeners();
  }

  @override
  List<GroupSummary> get groups => List.unmodifiable(_groups);

  @override
  List<GroupMember> members(String groupId) =>
      List.unmodifiable(_members[groupId] ?? const []);

  @override
  Future<GroupSummary> createGroup(String name) async {
    final id = 'g${_seq++}';
    final me = _identity;
    final mine = me == null
        ? <GroupMember>[]
        : <GroupMember>[GroupMember(me.memberId, me.name)];
    _members[id] = mine;
    _members[id]!.addAll(
        const [GroupMember('tom00', 'Tom'), GroupMember('ana00', 'Anaïs')]);
    final secret = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      secret[i] = (id.hashCode + i) & 0xFF;
    }
    _groupSecret[id] = secret;
    final summary = GroupSummary(id, name, _members[id]!.length);
    _groups.add(summary);
    notifyListeners();
    return summary;
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    _members.remove(groupId);
    _groupSecret.remove(groupId); // le secret part avec le groupe
    notifyListeners();
  }

  @override
  String inviteFor(String groupId) {
    final me = _identity;
    final name = _groups
        .firstWhere((g) => g.id == groupId,
            orElse: () => const GroupSummary('', '', 0))
        .name;
    return GroupInvite(
      groupId: groupId,
      groupName: name,
      groupSecret: _groupSecret[groupId] ?? Uint8List(32),
      creatorName: me?.name ?? 'Inconnu',
      creatorSignPublicKey: Uint8List(32),
    ).encode();
  }

  @override
  Future<void> joinFromInvite(String payload) async {
    final invite = GroupInvite.decode(payload);
    final id = invite.groupId;
    if (_groups.any((g) => g.id == id)) return; // déjà rejoint : idempotent
    _groupSecret[id] = invite.groupSecret;
    final me = _identity;
    _members[id] = [
      GroupMember('creator', invite.creatorName),
      if (me != null) GroupMember(me.memberId, me.name),
    ];
    final name = invite.groupName.isEmpty ? invite.groupId : invite.groupName;
    _groups.add(GroupSummary(id, name, _members[id]!.length));
    notifyListeners();
  }

  @override
  AppSettings get settings => _settings;

  @override
  void updateSettings(AppSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  @override
  GeoPoint get myPosition => GeoPoint(_settings.myLat, _settings.myLon);

  @override
  Future<GeoPoint> currentPosition() async => myPosition;

  @override
  Stream<GeoPoint> positionUpdates() => const Stream.empty();

  @override
  Future<void> ensureConnected() async {}

  @override
  Future<void> refreshGroups() async {}

  @override
  Future<void> requestLocation({
    required String groupId,
    required String targetId,
    bool live = false,
  }) async {
    final ids = targetId == kAllMembers
        ? (_members[groupId] ?? const [])
            .map((m) => m.memberId)
            .where((id) => id != _identity?.memberId)
            .toList()
        : [targetId];
    var i = 0;
    for (final id in ids) {
      _located[id] = LocatedPosition(
        id,
        GeoPoint(myPosition.latitude + 0.002 + i * 0.0015,
            myPosition.longitude + 0.001 - i * 0.0012),
        10,
        DateTime.now().millisecondsSinceEpoch,
      );
      i++;
    }
    notifyListeners();
  }

  @override
  LocatedPosition? located(String responderId) => _located[responderId];
}
