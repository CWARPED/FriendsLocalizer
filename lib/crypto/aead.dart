import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Chiffrement authentifié ChaCha20-Poly1305.
/// Format de sortie compact : nonce(12) | mac(16) | ciphertext.
class Aead {
  static final _algo = Chacha20.poly1305Aead();

  static Future<Uint8List> encrypt(List<int> clear, List<int> key) async {
    final secretKey = SecretKey(key);
    final box = await _algo.encrypt(clear, secretKey: secretKey);
    final out = BytesBuilder();
    out.add(box.nonce);       // 12 octets
    out.add(box.mac.bytes);   // 16 octets
    out.add(box.cipherText);
    return out.toBytes();
  }

  static Future<Uint8List> decrypt(Uint8List packed, List<int> key) async {
    final nonce = packed.sublist(0, 12);
    final mac = packed.sublist(12, 28);
    final cipherText = packed.sublist(28);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final clear = await _algo.decrypt(box, secretKey: SecretKey(key));
    return Uint8List.fromList(clear);
  }
}
