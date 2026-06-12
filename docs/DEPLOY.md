# Déployer le relais FriendsLocalizer

Cible : faire tourner le relais sur un NAS, derrière un reverse-proxy
**nginx-proxy + acme-companion** (TLS Let's Encrypt automatique), accessible sous
un **chemin** de ton domaine existant : `wss://ton-domaine/fl`.

Pourquoi un chemin et pas un sous-domaine : nginx-proxy route un domaine vers une
seule app. Si ton domaine est déjà servi par une autre app (et qu'un sous-domaine
n'est pas possible — ex. certains dyndns à nom unique), on partage le domaine
**par chemin** : l'app principale reste à la racine `/`, le relais vit sous `/fl`.

## 1. Récupérer l'image

```bash
docker pull cwarp/friendslocalizer-relay:latest
```

Image multi-arch (amd64 + arm64) : le NAS tire automatiquement la bonne.

## 2. Ajouter le relais à ton infra nginx-proxy

Le plus simple : **ajoute le service `fl-relay`** dans le `docker-compose.yml` où
tournent déjà `nginx-proxy` + ton app (il partage alors le réseau automatiquement) :

```yaml
  fl-relay:
    image: cwarp/friendslocalizer-relay:latest
    expose:
      - "8080"
    environment:
      VIRTUAL_HOST: ton-domaine            # le même que ton app
      VIRTUAL_PATH: /fl/                    # le relais sous /fl
      VIRTUAL_DEST: /                       # retire /fl avant de transmettre
      VIRTUAL_PORT: "8080"
    restart: unless-stopped
    depends_on:
      - nginx-proxy
```

Et **ajoute une ligne à ton app principale** pour qu'elle reste à la racine quand
le routage par chemin est activé :

```yaml
    environment:
      VIRTUAL_HOST: ton-domaine
      VIRTUAL_PATH: /                       # <-- AJOUTER : garde l'app à la racine
      VIRTUAL_PORT: "8080"
      LETSENCRYPT_HOST: ton-domaine
```

Puis :

```bash
docker compose up -d
```

> Le certificat est déjà obtenu par ton app principale (`LETSENCRYPT_HOST`) ; le
> relais n'en a pas besoin, il réutilise le même domaine.

*(Variante : lancer `deploy/docker-compose.yml` à part en rattachant le relais au
réseau externe de nginx-proxy — voir les commentaires du fichier.)*

## 3. Vérifier

Depuis un téléphone en **4G** (hors Wi-Fi maison) :

```
https://ton-domaine/fl/health
```

Doit répondre `ok`. Si oui, le TLS + le routage sont bons. (nginx-proxy gère le
WebSocket tout seul.)

## 4. Configurer l'app

Dans l'app → Réglages → adresse du serveur relais :

```
wss://ton-domaine/fl
```

Aucun autre réglage : l'app ajoute seule `/relay` (WebSocket) et utilise
`/directory` (annuaire) en HTTPS, tous deux sous `/fl`.

## Notes

- **Sécurité** : le relais est exposé sans authentification. C'est sûr car tout
  est chiffré de bout en bout, mais l'annuaire expose des métadonnées publiques
  (noms, clés publiques, identifiants de groupe). Ne pas y mettre de données
  sensibles côté serveur.
- **Logs** : `docker logs -f fl-relay`.
- **Mise à jour** : `docker compose pull && docker compose up -d`.
- **Reverse-proxy classique** (Nginx écrit à la main, Traefik, Caddy…) : route
  simplement `/fl/` vers le conteneur `:8080` en retirant le préfixe, avec les
  en-têtes d'upgrade WebSocket.
