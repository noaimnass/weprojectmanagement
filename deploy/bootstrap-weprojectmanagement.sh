#!/usr/bin/env bash
# Reconstruit le dépôt WeProjectManagement à partir d'OpenProject + le correctif WeProjectManagement.
# Usage : ./bootstrap-weprojectmanagement.sh <chemin-du-patch> [dossier-cible]
set -euo pipefail

PATCH="${1:?Chemin du fichier weprojectmanagement-*.patch}"
TARGET="${2:-weprojectmanagement}"
PATCH_ABS="$(cd "$(dirname "$PATCH")" && pwd)/$(basename "$PATCH")"
BASE_COMMIT="de387b5d440ceffd8ea8cdbe9f8050c9ac8267ef"   # opf/openproject, branche dev, 17 octobre 2026

git clone --filter=blob:none https://github.com/opf/openproject.git "$TARGET"
cd "$TARGET"
git checkout -b weprojectmanagement "$BASE_COMMIT"
git am --3way "$PATCH_ABS"
echo "WeProjectManagement prêt dans $(pwd) (branche weprojectmanagement)."
echo "Suite : cd $TARGET && cp deploy/.env.example deploy/.env && docker compose -f deploy/docker-compose.yml --env-file deploy/.env build"
