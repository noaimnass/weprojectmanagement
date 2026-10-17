# Déployer WeProjectManagement

Image tout-en-un construite depuis ce dépôt (Dockerfile OpenProject de production, cible `all-in-one`), base PostgreSQL 17, cache Memcached.

## Prérequis (VPS Hostinger ou autre)

- Docker 24+ et le plugin Compose (`docker compose version`).
- 4 Go de RAM minimum pour la construction de l'image (le front Angular est compilé pendant le build), 2 Go pour l'exécution.
- Un nom de domaine pointant vers le serveur (ex. `wpm.weworld.tech`) et un reverse proxy TLS (Caddy, Traefik ou Nginx + certbot) devant le port `APP_PORT`.

## Premier démarrage

```bash
git clone <votre dépôt weprojectmanagement> && cd weprojectmanagement
cp deploy/.env.example deploy/.env
openssl rand -hex 64        # → SECRET_KEY_BASE dans deploy/.env
nano deploy/.env            # mot de passe base, hôte, SMTP…
docker compose -f deploy/docker-compose.yml --env-file deploy/.env build   # 20 à 40 min la première fois
docker compose -f deploy/docker-compose.yml --env-file deploy/.env up -d
docker compose -f deploy/docker-compose.yml --env-file deploy/.env logs -f app
```

Au premier démarrage, les migrations (dont celles du module Pilotage) et les données d'amorçage s'exécutent. Connexion : `admin` / `ADMIN_PASSWORD` (changement demandé à la première connexion).

## Après l'installation

1. **Administration › Pilotage** : devise, unité budgétaire, seuils d'éligibilité, classes A/B/C, cadences, catégories et axes.
2. **Rôles et permissions** : donner « Consulter le pilotage du portefeuille » et « Animer le pilotage du portefeuille » au rôle global du PMO ; « Consulter / Gérer le pilotage du projet » aux rôles projet (chef de projet, membre).
3. **Instances de gouvernance** : `docker compose -f deploy/docker-compose.yml exec app bundle exec rake pilotage:seed_governance`.
4. **Activer le pilotage sur tous les projets existants** : `… exec app bundle exec rake pilotage:enable_all`.
5. **Instance de démonstration uniquement** : `… exec app bundle exec rake pilotage:demo` remplit fiches, jalons, registres et rapports fictifs (ne pas lancer en production avec des données réelles).
6. **Jeton Enterprise (optionnel)** : Administration › Édition Enterprise pour activer les add-ons d'OpenProject GmbH (essai gratuit ou abonnement).

## Mise à jour

```bash
git pull
docker compose -f deploy/docker-compose.yml --env-file deploy/.env build
docker compose -f deploy/docker-compose.yml --env-file deploy/.env up -d
```

## Sauvegarde

- Base : `docker compose -f deploy/docker-compose.yml exec db pg_dump -U weprojectmanagement weprojectmanagement > sauvegarde.sql`
- Fichiers : volume `opdata` (`/var/openproject/assets`).

## Reverse proxy (exemple Caddy)

```
wpm.weworld.tech {
  reverse_proxy localhost:8080
}
```

Avec `APP_HTTPS=true`, l'application génère des liens en https et attend l'en-tête `X-Forwarded-Proto: https` du proxy.
