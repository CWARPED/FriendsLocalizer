import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class Member {
  final String name;
  final List<int> signPublicKey; // 32 octets Ed25519
  const Member(this.name, this.signPublicKey);
}

/// Un groupe partage un secret [groupSecret] (Kg) et un roster de membres.
class Group {
  final String groupId;
  final Uint8List groupSecret; // Kg, 32 octets
  final List<Member> members;

  Group(this.groupId, this.groupSecret, this.members);

  /// Crée un groupe avec un Kg aléatoire de 32 octets.
  static Future<Group> create(String groupId) async {
    final algo = Chacha20.poly1305Aead();
    final key = await algo.newSecretKey();
    final bytes = await key.extractBytes();
    return Group(groupId, Uint8List.fromList(bytes), <Member>[]);
  }

  /// Clé de chiffrement dérivée de Kg via HKDF-SHA256 (info = "fl-enc").
  Future<Uint8List> encryptionKey() async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final out = await hkdf.deriveKey(
      secretKey: SecretKey(groupSecret),
      nonce: const <int>[], // salt vide (Kg déjà aléatoire)
      info: 'fl-enc'.codeUnits,
    );
    final bytes = await out.extractBytes();
    return Uint8List.fromList(bytes);
  }

  bool isMember(List<int> signPublicKey) {
    for (final m in members) {
      if (_constEq(m.signPublicKey, signPublicKey)) return true;
    }
    return false;
  }

  static bool _constEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
