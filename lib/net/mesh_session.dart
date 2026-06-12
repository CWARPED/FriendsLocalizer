import 'dart:convert';
import 'dart:math';
import '../app/member.dart';
import '../crypto/group.dart';
import '../crypto/identity.dart';
import '../mesh/config.dart';
import '../mesh/mesh_node.dart';
import '../mesh/real_scheduler.dart';
import '../app/location_service.dart';
import '../app/sensors.dart';
import 'directory_client.dart';
import 'server_gateway_transport.dart';

export '../app/location_service.dart' show LocatedPosition;

/// Assemble une session mesh complète : transport (WebSocket) + moteur
/// (`MeshNode`) + `LocationService`. Expose la demande de localisation.
class MeshSession {
  final ServerGatewayTransport transport;
  final String _groupId;
  late final MeshNode _node;
  late final LocationService _location;

  final Identity _identity;
  final String _myId;
  final Group _group;
  final DirectoryClient? _directory;

  void Function(LocatedPosition position)? onLocated;

  MeshSession({
    required Identity identity,
    required String myId,
    required Group group,
    required this.transport,
    required LocationProvider location,
    required Random random,
    MeshConfig config = const MeshConfig(),
    int Function()? nowMs,
    String? directoryBaseUrl,
  })  : _groupId = group.groupId,
        _identity = identity,
        _myId = myId,
        _group = group,
        _directory = directoryBaseUrl == null
            ? null
            : DirectoryClient(directoryBaseUrl) {
    final clock = nowMs ?? () => DateTime.now().millisecondsSinceEpoch;
    _location = LocationService(
      identity: identity,
      myId: myId,
      groups: [group],
      location: location,
      random: random,
      nowMs: clock,
      broadcast: (frame) => _node.broadcastSealed(frame),
    );
    _location.onLocated = (p) => onLocated?.call(p);
    _node = MeshNode(
      scheduler: RealScheduler(),
      transport: transport,
      config: config,
      random: random,
      onDeliver: (frame) => _location.handleIncoming(frame),
      bindInbound: (handleFrame, handleNeighbor) {
        transport.onFrame = handleFrame;
        transport.onNeighbor = handleNeighbor;
      },
    );
  }

  Future<void> start() => transport.start();
  Future<void> stop() => transport.stop();

  Future<void> requestLocation({
    required String targetId,
    bool live = false,
  }) =>
      _location.requestLocation(groupId: _groupId, targetId: targetId, live: live);

  /// Publie mon entrée publique (memberId, clé, nom) dans l'annuaire.
  Future<void> publishMe({required String name}) async {
    final dir = _directory;
    if (dir == null) return;
    await dir.publish(DirectoryEntry(
      groupId: _group.groupId,
      memberId: _myId,
      name: name,
      signPublicKeyB64: base64.encode(_identity.signPublicKey),
    ));
  }

  /// Récupère le roster de l'annuaire et ajoute les membres manquants au groupe.
  Future<void> syncRoster() async {
    final dir = _directory;
    if (dir == null) return;
    final entries = await dir.roster(_group.groupId);
    for (final e in entries) {
      final pub = base64.decode(e.signPublicKeyB64);
      if (!_group.isMember(pub)) {
        _group.members.add(Member(e.name, pub));
      }
    }
  }

  List<String> get rosterMemberIds =>
      _group.members.map((m) => memberId(m.signPublicKey)).toList();
}
