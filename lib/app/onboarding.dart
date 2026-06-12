import 'dart:convert';
import 'dart:typed_data';

/// Invitation à rejoindre un groupe, partagée par QR (en personne) ou lien.
/// Contient le secret de groupe Kg : à transmettre par un canal de confiance.
class GroupInvite {
  final String groupId;
  final String groupName;
  final Uint8List groupSecret;            // Kg, 32 octets
  final String creatorName;
  final Uint8List creatorSignPublicKey;   // 32 octets Ed25519

  GroupInvite({
    required this.groupId,
    required this.groupName,
    required this.groupSecret,
    required this.creatorName,
    required this.creatorSignPublicKey,
  });

  /// Sérialise en JSON puis base64 (texte compact pour un QR / une URL).
  String encode() {
    final map = {
      'v': 1,
      'g': groupId,
      'gn': groupName,
      'k': base64.encode(groupSecret),
      'n': creatorName,
      'p': base64.encode(creatorSignPublicKey),
    };
    return base64.encode(utf8.encode(json.encode(map)));
  }

  static GroupInvite decode(String payload) {
    try {
      final map = json.decode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
      if ((map['v'] as int?) != 1) {
        throw FormatException('version non supportée : ${map['v']}');
      }
      return GroupInvite(
        groupId: map['g'] as String,
        groupName: map['gn'] as String,
        groupSecret: base64.decode(map['k'] as String),
        creatorName: map['n'] as String,
        creatorSignPublicKey: base64.decode(map['p'] as String),
      );
    } catch (e) {
      throw FormatException('invitation invalide : $e');
    }
  }
}

/// Extrait le payload d'un lien `fl://join#<payload>` ou d'un payload nu
/// (la partie après `#`, sinon la chaîne nettoyée).
String extractInvitePayload(String raw) {
  final t = raw.trim();
  final idx = t.indexOf('#');
  return idx >= 0 ? t.substring(idx + 1) : t;
}

/// Tente de décoder une chaîne (scannée ou collée) en [GroupInvite] ;
/// renvoie `null` si ce n'est pas une invitation valide.
GroupInvite? tryDecodeInvite(String raw) {
  try {
    return GroupInvite.decode(extractInvitePayload(raw));
  } catch (_) {
    return null;
  }
}
