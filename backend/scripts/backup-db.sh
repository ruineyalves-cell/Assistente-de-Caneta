#!/usr/bin/env bash
# backup-db.sh — snapshot do Postgres Recorpo (Passo 1).
#
# Uso:
#   1) pegar a EXTERNAL Database URL no dashboard Render:
#      https://dashboard.render.com/d/<seu-id>/info
#   2) exportar como env var:
#      export DATABASE_URL="postgresql://user:pass@ohio-postgres.render.com/recorpo?sslmode=require"
#   3) rodar:
#      bash backend/scripts/backup-db.sh
#
# Gera dois arquivos em backups/ com timestamp:
#   - recorpo_YYYYMMDD_HHMMSS.dump   (formato custom, pra restore rápido)
#   - recorpo_YYYYMMDD_HHMMSS.sql.gz (formato SQL, legível, backup redundante)
#
# Restore:
#   pg_restore --clean --if-exists -d "$DATABASE_URL" backups/recorpo_XXXX.dump
#
# Requer pg_dump instalado (postgresql-client no Linux, `brew install postgresql`
# no macOS, ou baixar postgresql do site em Windows).

set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "❌ DATABASE_URL não definida. Pegue no dashboard do Render (External URL)."
  exit 1
fi

STAMP=$(date +%Y%m%d_%H%M%S)
DEST_DIR="$(dirname "$0")/../../backups"
mkdir -p "$DEST_DIR"

echo "→ Backup em formato custom (para pg_restore)..."
pg_dump --format=custom --file="$DEST_DIR/recorpo_${STAMP}.dump" "$DATABASE_URL"

echo "→ Backup em SQL simples comprimido..."
pg_dump --format=plain "$DATABASE_URL" | gzip -9 > "$DEST_DIR/recorpo_${STAMP}.sql.gz"

echo "✓ Backup pronto em $DEST_DIR/"
ls -lh "$DEST_DIR/recorpo_${STAMP}."*
echo
echo "GUARDE ESSES ARQUIVOS FORA DO PC (Google Drive / iCloud / pendrive)."
echo "Depois do upgrade do Postgres pra Basic, execute o restore no novo banco."
