/// URL WebSocket complète du relais : ajoute `/relay` si absent (idempotent).
/// L'utilisateur peut donc saisir `ws://host:8080` ou `ws://host:8080/relay`.
String relayWsUrl(String serverUrl) {
  var u = serverUrl.trim();
  while (u.endsWith('/')) {
    u = u.substring(0, u.length - 1);
  }
  return u.endsWith('/relay') ? u : '$u/relay';
}

/// Déduit l'URL de base HTTP de l'annuaire à partir de l'URL WebSocket du relais.
/// `ws://host/relay` -> `http://host` ; `wss://host` -> `https://host`.
String directoryBaseFromWs(String wsUrl) {
  var u = wsUrl.trim();
  if (u.endsWith('/relay')) u = u.substring(0, u.length - '/relay'.length);
  if (u.startsWith('wss://')) return 'https://${u.substring('wss://'.length)}';
  if (u.startsWith('ws://')) return 'http://${u.substring('ws://'.length)}';
  return u;
}
