# Déployer WeProjectManagement

Image tout-en-un construite depuis ce dépôt (Dockerfile OpenProject de production, cible `all-in-one`), base PostgreSQL 17, cache Memcached.

## Hostinger : quel plan ?

L'application (Ruby on Rails + PostgreSQL + Docker) ne fonctionne **pas** sur l'hébergement web mutualisé de Hostinger (plans Premium / Business / Cloud, anciennement « Unlimited ») : ces plans n'offrent ni Docker, ni PostgreSQL, ni processus Ruby persistant. Il faut un **VPS Hostinger** : KVM 2 (2 vCPU, 8 Go de RAM, 100 Go NVMe) au minimum, car la construction de l'image compile le front Angular ; KVM 4 pour plus de 50 utilisateurs actifs. Choisir un centre de données européen (France ou Pays-Bas) pour la latence depuis le Maroc.

## Prérequis (VPS Hostinger ou autre)

- Docker 24+ et le plugin Compose (`docker compose version`).
- 4 Go de RAM minimum pour la construction de l'image (le front Angular est compilé pendant le build), 2 Go pour l'exécution.
- Un nom de domaine pointant vers le serveur (ex. `wpm.weworld.tech`) et un reverse proxy TLS (Caddy, Traefik ou Nginx + certbot) devant le port `APP_PORT`.

## Pas à pas sur un VPS Hostinger (KVM 2, Ubuntu 24.04)

1. **Commander le VPS** dans hPanel › VPS : plan KVM 2, système Ubuntu 24.04 (prendre le modèle « avec Docker » s'il est proposé, sinon Docker sera installé à l'étape 4), centre de données Europe. Noter l'adresse IP et définir le mot de passe root.
2. **DNS** : hPanel › Domaines › weworld.tech › DNS : ajouter un enregistrement **A** `wpm` → IP du VPS (TTL par défaut). Compter quelques minutes de propagation.
3. **Préparer le serveur** (depuis votre poste : `ssh root@IP`) :
   ```bash
   apt update && apt -y upgrade
   fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab
   apt -y install ufw git curl && ufw allow OpenSSH && ufw allow 80 && ufw allow 443 && ufw --force enable
   ```
4. **Docker** (si le modèle ne l'incluait pas) : `curl -fsSL https://get.docker.com | sh` puis `docker compose version`.
5. **Récupérer le code** : copier `weprojectmanagement-1.0.0.patch` et `bootstrap-weprojectmanagement.sh` sur le serveur (`scp fichier root@IP:/opt/`), puis :
   ```bash
   cd /opt && chmod +x bootstrap-weprojectmanagement.sh && ./bootstrap-weprojectmanagement.sh weprojectmanagement-1.0.0.patch
   ```
   (ou `git clone` de votre dépôt GitHub si la branche y est poussée).
6. **Configurer** : `cd /opt/weprojectmanagement && cp deploy/.env.example deploy/.env && nano deploy/.env` — `DB_PASSWORD`, `SECRET_KEY_BASE` (`openssl rand -hex 64`), `APP_HOST=wpm.weworld.tech`, `APP_HTTPS=true`, `ADMIN_PASSWORD`, `ADMIN_MAIL`, SMTP Hostinger (`smtp.hostinger.com`, port 587, l'adresse e-mail créée dans hPanel › E-mails et son mot de passe), `MAIL_FROM`.
7. **Construire et lancer** (20 à 40 minutes la première fois) :
   ```bash
   docker compose -f deploy/docker-compose.yml --env-file deploy/.env build
   docker compose -f deploy/docker-compose.yml --env-file deploy/.env up -d
   docker compose -f deploy/docker-compose.yml --env-file deploy/.env logs -f app
   ```
   Attendre les migrations puis le message d'écoute du serveur ; `curl -I http://localhost:8080` doit répondre.
8. **HTTPS avec Caddy** (certificat Let's Encrypt automatique) :
   ```bash
   apt -y install debian-keyring debian-archive-keyring apt-transport-https
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
   apt update && apt -y install caddy
   printf 'wpm.weworld.tech {\n  reverse_proxy localhost:8080\n}\n' > /etc/caddy/Caddyfile
   systemctl reload caddy
   ```
   Ouvrir https://wpm.weworld.tech et se connecter avec `admin` / `ADMIN_PASSWORD`.
9. **Après la première connexion** : suivre la section « Après l'installation » ci-dessous (paramètres Pilotage, rôles, `rake pilotage:seed_governance`, `rake pilotage:enable_all`).
10. **Exploitation** : activer les sauvegardes automatiques du VPS dans hPanel, programmer un `pg_dump` hebdomadaire (section Sauvegarde), mettre à jour avec la section Mise à jour.

## Tester sans serveur : GitHub Codespaces

Le dépôt contient une configuration Codespaces (`.devcontainer/devcontainer.json`, machine 4 cœurs / 16 Go, Docker, port 8080 transféré). Depuis la page du dépôt sur GitHub : **Code › Codespaces › New with options**, machine « 4-core », créer. Dans le terminal du Codespace :

```bash
bash deploy/codespace.sh
```

Le script écrit `deploy/.env` avec l'URL du Codespace, construit l'image (20 à 40 min), démarre, puis amorce les instances, le pilotage et les données de démonstration. Il affiche l'adresse finale (`https://<codespace>-8080.app.github.dev`, `admin` / `admin1234`). Onglet **Ports** : passer le port 8080 en « Public » pour montrer la démo à quelqu'un d'autre. Arrêter le Codespace quand il ne sert pas (il consomme le quota gratuit tant qu'il tourne ; il s'arrête seul après 30 minutes d'inactivité). `bash deploy/codespace.sh --no-demo` pour une instance vierge.

## Premier démarrage (générique)

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
