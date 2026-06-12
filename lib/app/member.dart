/// Cible spéciale : tous les membres du groupe.
const String kAllMembers = '*';

/// Identifiant stable d'un membre = hex minuscule de sa clé publique Ed25519.
String memberId(List<int> signPublicKey) {
  final sb = StringBuffer();
  for (final b in signPublicKey) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
