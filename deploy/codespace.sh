#!/usr/bin/env bash
# Démarre WeProjectManagement dans un GitHub Codespace : configuration automatique de l'URL,
# construction de l'image, démarrage, amorçage de la démo. Usage : bash deploy/codespace.sh [--no-demo]
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${CODESPACE_NAME:-}" ]; then
  echo "Ce script est prévu pour un GitHub Codespace (variable CODESPACE_NAME absente)." >&2
  exit 1
fi

HOST="${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
ENV_FILE="deploy/.env"
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<ENV
DB_PASSWORD=$(openssl rand -hex 16)
SECRET_KEY_BASE=$(openssl rand -hex 64)
APP_HOST=${HOST}
APP_HTTPS=true
APP_PORT=8080
APP_LANGUAGE=fr
APP_TITLE=WeProjectManagement
ADMIN_PASSWORD=admin1234
ADMIN_MAIL=admin@weworld.tech
MAIL_METHOD=smtp
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_DOMAIN=
SMTP_USER=
SMTP_PASSWORD=
SMTP_AUTH=plain
MAIL_FROM=weprojectmanagement@weworld.tech
ENV
  echo "Fichier $ENV_FILE créé (hôte : $HOST)."
fi

COMPOSE="docker compose -f deploy/docker-compose.yml --env-file $ENV_FILE"
echo "Construction de l'image (20 à 40 minutes la première fois)…"
$COMPOSE build
echo "Démarrage…"
$COMPOSE up -d
echo "Attente de la base et des migrations…"
for i in $(seq 1 120); do
  if curl -fsS -o /dev/null http://localhost:8080/health_check 2>/dev/null; then break; fi
  sleep 10
done
if [ "${1:-}" != "--no-demo" ]; then
  echo "Amorçage des instances de gouvernance, du pilotage et des données de démonstration…"
  $COMPOSE exec -T app bundle exec rake pilotage:seed_governance pilotage:enable_all pilotage:demo || true
fi
echo
echo "WeProjectManagement est prêt : https://${HOST}  (admin / admin1234)"
echo "Journal : $COMPOSE logs -f app   —   Arrêt : $COMPOSE down"
