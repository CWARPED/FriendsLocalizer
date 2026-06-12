import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'identity.dart';

class Signing {
  static final _ed = Ed25519();

  /// Signe [message] avec la clé Ed25519 de [identity]. Renvoie 64 octets.
  static Future<Uint8List> sign(List<int> message, Identity identity) async {
    final sig = await _ed.sign(message, keyPair: identity.signKeyPair);
    return Uint8List.fromList(sig.bytes);
  }

  /// Vérifie [signature] (64 octets) sur [message] avec [signPublicKey] (32 octets).
  /// Renvoie false si la signature est malformée ou invalide.
  static Future<bool> verify(
    List<int> message,
    List<int> signature,
    List<int> signPublicKey,
  ) async {
    try {
      final sig = Signature(
        signature,
        publicKey: SimplePublicKey(signPublicKey, type: KeyPairType.ed25519),
      );
      return await _ed.verify(message, signature: sig);
    } catch (_) {
      return false;
    }
  }
}
