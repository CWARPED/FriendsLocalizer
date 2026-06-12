/// Entrée d'annuaire : données PUBLIQUES uniquement (jamais de secret/Kg).
class MemberEntry {
  final String groupId;
  final String memberId;
  final String name;
  final String signPublicKeyB64; // clé publique Ed25519 en base64 (publique)

  const MemberEntry({
    required this.groupId,
    required this.memberId,
    required this.name,
    required this.signPublicKeyB64,
  });

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'memberId': memberId,
        'name': name,
        'pub': signPublicKeyB64,
      };

  factory MemberEntry.fromJson(Map<String, dynamic> j) => MemberEntry(
        groupId: j['groupId'] as String,
        memberId: j['memberId'] as String,
        name: j['name'] as String,
        signPublicKeyB64: j['pub'] as String,
      );
}

/// Annuaire en mémoire : groupId -> (memberId -> entrée).
class KeyDirectory {
  final Map<String, Map<String, MemberEntry>> _byGroup = {};

  void publish(MemberEntry e) {
    (_byGroup[e.groupId] ??= {})[e.memberId] = e;
  }

  List<MemberEntry> roster(String groupId) =>
      _byGroup[groupId]?.values.toList() ?? const [];
}
