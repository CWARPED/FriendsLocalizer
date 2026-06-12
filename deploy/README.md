# Déploiement du relais

Artefacts pour héberger `cwarp/friendslocalizer-relay` derrière un reverse-proxy
**nginx-proxy + acme-companion** (TLS Let's Encrypt automatique). Marche à suivre
complète : [../docs/DEPLOY.md](../docs/DEPLOY.md).

- `docker-compose.yml` — service du relais avec les variables `VIRTUAL_*` que
  nginx-proxy lit pour le router par chemin (`/fl`) sur ton domaine existant.

> Pas de bloc Nginx à écrire : nginx-proxy génère la config tout seul à partir des
> variables d'environnement du conteneur.
