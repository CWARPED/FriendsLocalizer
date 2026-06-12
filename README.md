# FriendsLocalizer

Localisateur d'amis **chiffré de bout en bout**, pensé pour les festivals :
retrouve tes amis sur un radar, même sans réseau fiable. Les positions sont
chiffrées sur ton appareil ; le serveur ne fait que relayer des messages
qu'il ne peut pas lire.

## Modèle de confiance / vie privée

- **Chiffrement E2E** : les clés de groupe et d'identité restent **sur les
  appareils**. Le relais ne déchiffre jamais les positions.
- **Le relais est un simple relais, non fiable par conception.** Il transporte
  des messages chiffrés et héberge un annuaire de **données publiques** (nom
  affiché, clé publique, identifiant de groupe) servant à l'échange de clés.
- Aucune position n'est stockée côté serveur.

## Fonctions

- Groupes (création, invitation par lien ou **QR code**).
- **Radar** orienté (boussole), points colorés par ami, distances.
- **GPS réel** sur mobile.
- **Mode festival** : reste localisable même appli en arrière-plan (Android).
- Bluetooth maillé (BLE) : prévu.

## Architecture

```
App mobile  ──WebSocket chiffré──►  Relais (shelf/Dart)  ◄── autres apps
     │                                   │
     └────── annuaire (HTTPS) ───────────┘   (clés publiques, données publiques)
```

- App : Flutter (`lib/`), crypto + mesh + UI.
- Relais : pur-Dart (`bin/server.dart`, `lib/server/`), sans dépendance Flutter.

## Construire l'app Android

```bash
flutter pub get
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
```

## Lancer le relais

En local :

```bash
dart compile exe bin/server.dart -o server && PORT=8080 ./server
```

En Docker :

```bash
docker run -p 8080:8080 cwarp/friendslocalizer-relay:latest
```

## Héberger le relais (auto-hébergement)

Voir **[docs/DEPLOY.md](docs/DEPLOY.md)** : conteneur derrière un reverse-proxy
Nginx + TLS, et configuration de l'app en `wss://`.

## Licence

AGPL-3.0 — Copyright (C) 2026 CWARP. Voir [LICENSE](LICENSE).

## Statut

Android d'abord (le mode festival en arrière-plan repose sur un service
avant-plan Android ; iOS ne permet pas ce fonctionnement). Projet en
développement actif.
