// lib/mesh/simulator.dart
import 'dart:math';
import 'dart:typed_data';
import 'config.dart';
import 'mesh_engine.dart';
import 'scheduler.dart';
import 'transport.dart';

/// Un nœud du simulateur : position 2D, moteur, et journal des livraisons.
class SimNode {
  final int id;
  double x;
  double y;
  late final MeshEngine engine;
  final List<Uint8List> delivered = [];
  SimNode(this.id, this.x, this.y);
}

/// Simulateur N-nœuds en mémoire. Implémente le transport : une diffusion
/// atteint les nœuds à portée après un délai de propagation, avec perte
/// optionnelle. Pilote un temps virtuel partagé.
class Simulator {
  final VirtualScheduler scheduler;
  /// RNG unique et graine, partagé par tous les moteurs ET le simulateur.
  /// Tous les tirages (backoff des moteurs, perte du simulateur) viennent du
  /// même flux : les résultats sont parfaitement reproductibles pour une graine,
  /// un nombre de nœuds et une config donnés — mais changer l'un de ces
  /// paramètres décale les sous-séquences RNG de tous les autres usages.
  final Random random;
  final double range;
  final double lossProb;
  final int propDelayMs;
  final List<SimNode> nodes = [];
  int totalTransmissions = 0;

  Simulator({
    required this.scheduler,
    required this.random,
    this.range = 100,
    this.lossProb = 0,
    this.propDelayMs = 5,
  });

  SimNode addNode(int id, double x, double y, MeshConfig config) {
    final node = SimNode(id, x, y);
    final transport = _SimTransport(this, node);
    node.engine = MeshEngine(
      scheduler: scheduler,
      transport: transport,
      config: config,
      random: random,
      onDeliver: (frame) => node.delivered.add(frame),
    );
    nodes.add(node);
    return node;
  }

  void _broadcastFrom(SimNode from, Uint8List frame) {
    totalTransmissions++;
    final r2 = range * range;
    for (final n in nodes) {
      if (identical(n, from)) continue;
      final dx = n.x - from.x;
      final dy = n.y - from.y;
      if (dx * dx + dy * dy <= r2) {
        if (lossProb <= 0 || random.nextDouble() >= lossProb) {
          scheduler.schedule(propDelayMs, () => n.engine.handleInbound(frame));
        }
      }
    }
  }
}

class _SimTransport implements MeshTransport {
  final Simulator sim;
  final SimNode node;
  _SimTransport(this.sim, this.node);
  @override
  void send(Uint8List frame) => sim._broadcastFrom(node, frame);
}
