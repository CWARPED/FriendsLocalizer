// test/mesh/simulator_test.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/mesh/config.dart';
import 'package:friends_localizer/mesh/scheduler.dart';
import 'package:friends_localizer/mesh/simulator.dart';

Uint8List buildFrame(Uint8List msgId, int ttl) => Envelope(
      msgId: msgId,
      type: 1,
      ttl: ttl,
      timestampMs: 0,
      senderPub: Uint8List(32),
      ciphertext: Uint8List.fromList([1, 2, 3]),
      signature: Uint8List(64),
    ).toBytes();

Uint8List idBytes(int seed) =>
    Uint8List.fromList(List<int>.generate(16, (i) => (i + seed) & 0xFF));

/// Construit une grille p×p de nœuds espacés de [spacing], portée [range].
Simulator grid(int p, double spacing, double range, MeshConfig config) {
  final sim = Simulator(
    scheduler: VirtualScheduler(),
    random: Random(7),
    range: range,
  );
  var nextId = 0;
  for (var r = 0; r < p; r++) {
    for (var c = 0; c < p; c++) {
      sim.addNode(nextId++, c * spacing, r * spacing, config);
    }
  }
  return sim;
}

void main() {
  test('couverture complète : un message atteint tous les nœuds connectés une fois', () {
    // Grille 5x5, espacement 50, portée 75 -> chaque nœud joint ses 8 voisins.
    // Sans suppression (seuil élevé) : chaque nœud relaie une fois, la dédup
    // garantit une couverture complète et la terminaison.
    final sim = grid(5, 50, 75, const MeshConfig(suppressionThreshold: 1000,
        minBackoffMs: 5, maxBackoffMs: 15));
    final origin = sim.nodes[12]; // centre
    origin.engine.originate(buildFrame(idBytes(1), 16));
    sim.scheduler.runUntilIdle();

    for (final n in sim.nodes) {
      if (identical(n, origin)) continue;
      expect(n.delivered.length, 1, reason: 'noeud ${n.id}');
    }
  });

  test('la suppression réduit le nombre de transmissions à couverture égale', () {
    Simulator run(int k) {
      final sim = grid(5, 50, 75, MeshConfig(suppressionThreshold: k,
          minBackoffMs: 5, maxBackoffMs: 15));
      sim.nodes[12].engine.originate(buildFrame(idBytes(2), 16));
      sim.scheduler.runUntilIdle();
      return sim;
    }

    final noSuppression = run(1000); // seuil énorme -> chaque nœud relaie
    final withSuppression = run(3);

    for (final sim in [noSuppression, withSuppression]) {
      final covered = sim.nodes.where((n) => n.delivered.isNotEmpty).length;
      expect(covered, 24); // 25 - origine
    }
    expect(withSuppression.totalTransmissions,
        lessThan(noSuppression.totalTransmissions));
  });

  test('le TTL borne la propagation', () {
    final sim = Simulator(
      scheduler: VirtualScheduler(),
      random: Random(7),
      range: 60,
    );
    for (var i = 0; i < 5; i++) {
      sim.addNode(i, i * 50.0, 0, const MeshConfig(
          suppressionThreshold: 100, minBackoffMs: 5, maxBackoffMs: 5));
    }
    sim.nodes[0].engine.originate(buildFrame(idBytes(3), 2)); // 2 sauts max
    sim.scheduler.runUntilIdle();

    expect(sim.nodes[1].delivered.length, 1); // saut 1
    expect(sim.nodes[2].delivered.length, 1); // saut 2 (ttl tombe à 1, stop)
    expect(sim.nodes[3].delivered, isEmpty); // ttl=0 à l'arrivée : le moteur ne relaie pas
    expect(sim.nodes[4].delivered, isEmpty); // jamais atteint (TTL épuisé avant)
  });

  test('store-and-forward : un nœud mobile transporte le message entre deux clusters', () {
    final sim = Simulator(
      scheduler: VirtualScheduler(),
      random: Random(7),
      range: 60,
    );
    const cfg = MeshConfig(suppressionThreshold: 100, minBackoffMs: 5, maxBackoffMs: 5);
    final a = sim.addNode(0, 0, 0, cfg);        // cluster A
    final mobile = sim.addNode(1, 30, 0, cfg);  // porteur, près de A
    final b = sim.addNode(2, 1000, 0, cfg);     // cluster B, hors de portée

    a.engine.originate(buildFrame(idBytes(4), 1)); // ttl 1
    sim.scheduler.runUntilIdle();
    expect(mobile.delivered.length, 1); // le porteur a reçu
    expect(b.delivered, isEmpty);       // B trop loin

    mobile.x = 1000 + 30;
    // Le store-and-forward ré-émet la trame bufferisée telle quelle (ttl
    // inchangé) ; B reçoit ttl=1 et ne relaie pas plus loin (le porteur ne
    // consomme pas de saut, par conception).
    mobile.engine.onNeighborAppeared();
    sim.scheduler.runUntilIdle();
    expect(b.delivered.length, 1); // B reçoit grâce au store-and-forward
  });
}
