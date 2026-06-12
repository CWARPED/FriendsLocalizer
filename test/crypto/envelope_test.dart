import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/crypto/identity.dart';
import 'package:friends_localizer/crypto/group.dart';
import 'package:friends_localizer/crypto/envelope.dart';
import 'package:friends_localizer/crypto/messages.dart';

void main() {
  const msgType = 1; // request

  Future<(Identity, Group)> setup() async {
    final id = await Identity.generate();
    final g = Group(
      'g1',
      Uint8List.fromList(List<int>.generate(32, (i) => i)),
      [Member('me', id.signPublicKey)],
    );
    return (id, g);
  }

  test('seal puis open redonne le payload en clair pour un membre', () async {
    final (id, g) = await setup();
    final payload = LocationRequest(
      requestId: 'r1', targetId: 'alice', live: false).encode();
    final env = await Envelope.seal(
      type: msgType, ttl: 8, sender: id, group: g, payload: payload,
      msgId: Uint8List(16));
    final wire = env.toBytes();

    final parsed = Envelope.fromBytes(wire);
    final opened = await parsed.open(g);
    expect(opened, payload);
  });

  test('open échoue si l\'émetteur n\'est pas dans le roster', () async {
    final (id, _) = await setup();
    final outsiderGroup = Group('g1',
      Uint8List.fromList(List<int>.generate(32, (i) => i)),
      const []); // roster vide
    final payload = Uint8List.fromList([1, 2, 3]);
    final env = await Envelope.seal(
      type: msgType, ttl: 8, sender: id, group: outsiderGroup,
      payload: payload, msgId: Uint8List(16));
    final parsed = Envelope.fromBytes(env.toBytes());
    expect(() => parsed.open(outsiderGroup), throwsA(isA<EnvelopeError>()));
  });

  test('open échoue si la signature est altérée', () async {
    final (id, g) = await setup();
    final env = await Envelope.seal(
      type: msgType, ttl: 8, sender: id, group: g,
      payload: Uint8List.fromList([1, 2, 3]), msgId: Uint8List(16));
    final wire = env.toBytes();
    wire[wire.length - 1] ^= 0xFF; // casse la signature
    final parsed = Envelope.fromBytes(wire);
    expect(() => parsed.open(g), throwsA(isA<EnvelopeError>()));
  });

  test('decrement TTL produit une enveloppe avec ttl-1 et même signature de contenu', () async {
    final (id, g) = await setup();
    final env = await Envelope.seal(
      type: msgType, ttl: 8, sender: id, group: g,
      payload: Uint8List.fromList([1, 2, 3]), msgId: Uint8List(16));
    final relayed = env.withDecrementedTtl();
    expect(relayed.ttl, 7);
    final opened = await Envelope.fromBytes(relayed.toBytes()).open(g);
    expect(opened, Uint8List.fromList([1, 2, 3]));
  });

  test('fromBytes rejette une trame tronquée avec EnvelopeError', () {
    final wire = Uint8List.fromList(List<int>.filled(50, 0)); // < 124 octets
    expect(() => Envelope.fromBytes(wire), throwsA(isA<EnvelopeError>()));
  });

  test('open échoue avec une mauvaise clé de groupe', () async {
    final (id, g) = await setup();
    final env = await Envelope.seal(
      type: msgType, ttl: 8, sender: id, group: g,
      payload: Uint8List.fromList([1, 2, 3]), msgId: Uint8List(16));
    // Autre groupe : même roster (émetteur valide) mais Kg différent.
    final otherGroup = Group(
      'g1',
      Uint8List.fromList(List<int>.generate(32, (i) => 255 - i)),
      [Member('me', id.signPublicKey)],
    );
    expect(() => Envelope.fromBytes(env.toBytes()).open(otherGroup),
        throwsA(isA<EnvelopeError>()));
  });

  test('withDecrementedTtl lève si TTL déjà à zéro', () async {
    final (id, g) = await setup();
    final env = await Envelope.seal(
      type: msgType, ttl: 0, sender: id, group: g,
      payload: Uint8List.fromList([1, 2, 3]), msgId: Uint8List(16));
    expect(() => env.withDecrementedTtl(), throwsA(isA<EnvelopeError>()));
  });

  test('round-trip préserve un timestamp non nul', () async {
    final (id, g) = await setup();
    final env = await Envelope.seal(
      type: msgType, ttl: 8, sender: id, group: g,
      payload: Uint8List.fromList([1, 2, 3]), msgId: Uint8List(16),
      timestampMs: 1700000000000);
    final parsed = Envelope.fromBytes(env.toBytes());
    expect(parsed.timestampMs, 1700000000000);
    final opened = await parsed.open(g);
    expect(opened, Uint8List.fromList([1, 2, 3]));
  });
}
