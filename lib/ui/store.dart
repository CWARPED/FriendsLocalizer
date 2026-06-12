/// Stockage clé->chaîne minimal et abstrait (pour rester testable sans plugin).
abstract class Store {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

/// Implémentation en mémoire (tests / desktop sans persistance).
class MemoryStore implements Store {
  final Map<String, String> _map;
  MemoryStore([Map<String, String>? initial]) : _map = {...?initial};

  @override
  String? getString(String key) => _map[key];

  @override
  Future<void> setString(String key, String value) async {
    _map[key] = value;
  }
}
