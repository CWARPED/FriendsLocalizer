import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Identité d'un utilisateur : une paire Ed25519 (signature, preuve
/// d'appartenance) et une paire X25519 (échange de clés).
class Identity {
  final SimpleKeyPairData signKeyPair;     // Ed25519
  final SimpleKeyPairData exchangeKeyPair; // X25519
  final Uint8List signPublicKey;
  final Uint8List exchangePublicKey;

  Identity._(
    this.signKeyPair,
    this.exchangeKeyPair,
    this.signPublicKey,
    this.exchangePublicKey,
  );

  static final _ed25519 = Ed25519();
  static final _x25519 = X25519();

  static Future<Identity> generate() async {
    final signKp = await _ed25519.newKeyPair();
    final exchKp = await _x25519.newKeyPair();
    final signData = await signKp.extract();
    final exchData = await exchKp.extract();
    final signPub = await signKp.extractPublicKey();
    final exchPub = await exchKp.extractPublicKey();
    return Identity._(
      signData,
      exchData,
      Uint8List.fromList(signPub.bytes),
      Uint8List.fromList(exchPub.bytes),
    );
  }

  /// Sérialise le matériel de clé privée en 64 octets :
  /// octets [0,32) = seed Ed25519 (32 octets)
  /// octets [32,64) = scalaire privé X25519 clampé (32 octets)
  Uint8List toBytes() {
    final out = Uint8List(64);
    out.setRange(0, 32, signKeyPair.bytes);
    out.setRange(32, 64, exchangeKeyPair.bytes);
    return out;
  }

  static Future<Identity> fromBytes(Uint8List bytes) async {
    if (bytes.length != 64) {
      throw ArgumentError.value(bytes.length, 'bytes.length', 'Expected 64 bytes');
    }
    final signSeed = bytes.sublist(0, 32);
    final exchSeed = bytes.sublist(32, 64);
    final signKp = await _ed25519.newKeyPairFromSeed(signSeed);
    final exchKp = await _x25519.newKeyPairFromSeed(exchSeed);
    final signData = await signKp.extract();
    final exchData = await exchKp.extract();
    final signPub = await signKp.extractPublicKey();
    final exchPub = await exchKp.extractPublicKey();
    return Identity._(
      signData,
      exchData,
      Uint8List.fromList(signPub.bytes),
      Uint8List.fromList(exchPub.bytes),
    );
  }
}
