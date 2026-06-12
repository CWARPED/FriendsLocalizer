import 'dart:typed_data';
import 'aead.dart';
import 'group.dart';
import 'identity.dart';
import 'signing.dart';

class EnvelopeError implements Exception {
  final String message;
  EnvelopeError(this.message);
  @override
  String toString() => 'EnvelopeError: $message';
}

/// Enveloppe de transport. Le TTL est hors signature (modifiable par les relais).
/// Octets signés : msgId | type | timestamp | senderPub | cipherLen | ciphertext.
class Envelope {
  final Uint8List msgId;        // 16
  final int type;               // 1
  final int ttl;                // 1 (hors signature)
  final int timestampMs;        // 8
  final Uint8List senderPub;    // 32 (Ed25519)
  final Uint8List ciphertext;   // variable
  final Uint8List signature;    // 64

  Envelope({
    required this.msgId,
    required this.type,
    required this.ttl,
    required this.timestampMs,
    required this.senderPub,
    required this.ciphertext,
    required this.signature,
  });

  /// Octets canoniques signés (n'incluent pas le TTL).
  static Uint8List _signedBytes(
    Uint8List msgId, int type, int timestampMs,
    List<int> senderPub, Uint8List ciphertext,
  ) {
    final b = BytesBuilder();
    b.add(msgId);
    b.addByte(type);
    final ts = ByteData(8)..setInt64(0, timestampMs, Endian.big);
    b.add(ts.buffer.asUint8List());
    b.add(senderPub);
    final cl = ByteData(2)..setUint16(0, ciphertext.length, Endian.big);
    b.add(cl.buffer.asUint8List());
    b.add(ciphertext);
    return b.toBytes();
  }

  static Future<Envelope> seal({
    required int type,
    required int ttl,
    required Identity sender,
    required Group group,
    required Uint8List payload,
    required Uint8List msgId,
    int timestampMs = 0,
  }) async {
    final key = await group.encryptionKey();
    final ciphertext = await Aead.encrypt(payload, key);
    final signed = _signedBytes(
      msgId, type, timestampMs, sender.signPublicKey, ciphertext);
    final signature = await Signing.sign(signed, sender);
    return Envelope(
      msgId: msgId,
      type: type,
      ttl: ttl,
      timestampMs: timestampMs,
      senderPub: sender.signPublicKey,
      ciphertext: ciphertext,
      signature: signature,
    );
  }

  /// Vérifie l'appartenance + la signature, puis déchiffre le payload.
  Future<Uint8List> open(Group group) async {
    if (!group.isMember(senderPub)) {
      throw EnvelopeError('émetteur hors roster');
    }
    final signed = _signedBytes(
      msgId, type, timestampMs, senderPub, ciphertext);
    final ok = await Signing.verify(signed, signature, senderPub);
    if (!ok) throw EnvelopeError('signature invalide');
    final key = await group.encryptionKey();
    try {
      return await Aead.decrypt(ciphertext, key);
    } catch (_) {
      throw EnvelopeError('déchiffrement échoué');
    }
  }

  Envelope withDecrementedTtl() {
    if (ttl <= 0) throw EnvelopeError('TTL déjà épuisé');
    return Envelope(
      msgId: msgId,
      type: type,
      ttl: ttl - 1,
      timestampMs: timestampMs,
      senderPub: senderPub,
      ciphertext: ciphertext,
      signature: signature,
    );
  }

  Uint8List toBytes() {
    final b = BytesBuilder();
    b.add(msgId);                              // 16
    b.addByte(type);                           // 1
    b.addByte(ttl);                            // 1
    final ts = ByteData(8)..setInt64(0, timestampMs, Endian.big);
    b.add(ts.buffer.asUint8List());            // 8
    b.add(senderPub);                          // 32
    final cl = ByteData(2)..setUint16(0, ciphertext.length, Endian.big);
    b.add(cl.buffer.asUint8List());            // 2
    b.add(ciphertext);                         // cipherLen
    b.add(signature);                          // 64
    return b.toBytes();
  }

  static Envelope fromBytes(Uint8List d) {
    const minLen = 16 + 1 + 1 + 8 + 32 + 2 + 64; // 124 octets sans ciphertext
    if (d.length < minLen) throw EnvelopeError('trame trop courte');
    try {
      var o = 0;
      final msgId = d.sublist(o, o + 16); o += 16;
      final type = d[o++];
      final ttl = d[o++];
      final timestampMs =
          ByteData.sublistView(d, o, o + 8).getInt64(0, Endian.big); o += 8;
      final senderPub = d.sublist(o, o + 32); o += 32;
      final cipherLen =
          ByteData.sublistView(d, o, o + 2).getUint16(0, Endian.big); o += 2;
      if (o + cipherLen + 64 > d.length) {
        throw EnvelopeError('cipherLen dépasse la trame');
      }
      final ciphertext = d.sublist(o, o + cipherLen); o += cipherLen;
      final signature = d.sublist(o, o + 64);
      return Envelope(
        msgId: msgId,
        type: type,
        ttl: ttl,
        timestampMs: timestampMs,
        senderPub: senderPub,
        ciphertext: ciphertext,
        signature: signature,
      );
    } on EnvelopeError {
      rethrow;
    } catch (e) {
      throw EnvelopeError('trame invalide: $e');
    }
  }
}
