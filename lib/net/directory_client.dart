import 'dart:convert';
import 'package:http/http.dart' as http;

/// Entrée d'annuaire (données publiques) côté client.
class DirectoryEntry {
  final String groupId;
  final String memberId;
  final String name;
  final String signPublicKeyB64;
  const DirectoryEntry({
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

  factory DirectoryEntry.fromJson(Map<String, dynamic> j) => DirectoryEntry(
        groupId: j['groupId'] as String,
        memberId: j['memberId'] as String,
        name: j['name'] as String,
        signPublicKeyB64: j['pub'] as String,
      );
}

/// Client HTTP de l'annuaire de clés publiques du serveur.
class DirectoryClient {
  final String baseUrl; // ex. http://host:8080
  final http.Client _http;
  DirectoryClient(this.baseUrl, {http.Client? client})
      : _http = client ?? http.Client();

  Future<void> publish(DirectoryEntry entry) async {
    await _http.post(
      Uri.parse('$baseUrl/directory'),
      headers: const {'content-type': 'application/json'},
      body: json.encode(entry.toJson()),
    );
  }

  Future<List<DirectoryEntry>> roster(String groupId) async {
    final res = await _http.get(Uri.parse('$baseUrl/directory/$groupId'));
    if (res.statusCode != 200) return const [];
    final list = json.decode(res.body) as List;
    return list
        .map((e) => DirectoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
