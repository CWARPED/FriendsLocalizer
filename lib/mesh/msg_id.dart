import 'dart:math';
import 'dart:typed_data';

/// Génère un identifiant de message aléatoire de 16 octets.
///
/// En production, passer `Random.secure()`. Les tests passent un `Random(seed)`
/// pour rester déterministes.
Uint8List generateMsgId(Random random) {
  final out = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    out[i] = random.nextInt(256);
  }
  return out;
}
