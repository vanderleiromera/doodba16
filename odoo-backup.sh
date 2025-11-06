#!/bin/bash

COMPOSE_FILE="prod.yaml"
DB_NAME="prod"
DB_USER="odoo"
DATE=$(date +%Y%m%d-%H%M)
BACKUP_DIR="./backups"

mkdir -p "$BACKUP_DIR"

DUMP_FILE="${BACKUP_DIR}/odoo_${DB_NAME}_${DATE}.dump"
FILESTORE_FILE="${BACKUP_DIR}/filestore_${DB_NAME}_${DATE}.tar.gz"

echo "📦 Compactando filestore antes de parar o Odoo..."
docker compose -f "$COMPOSE_FILE" exec -T odoo \
  tar czf "/tmp/filestore.tar.gz" "/var/lib/odoo/filestore/${DB_NAME}"

echo "📥 Copiando filestore para o host..."
docker compose -f "$COMPOSE_FILE" cp odoo:/tmp/filestore.tar.gz "$FILESTORE_FILE"

echo "🧹 Limpando arquivo temporário do container..."
docker compose -f "$COMPOSE_FILE" exec -T odoo rm /tmp/filestore.tar.gz

echo "🚧 Parando Odoo para backup do Banco..."
docker compose -f "$COMPOSE_FILE" stop odoo

echo "🗄️ Fazendo backup do banco de dados..."
docker compose -f "$COMPOSE_FILE" exec -T db \
    pg_dump -U "$DB_USER" -Fc "$DB_NAME" > "$DUMP_FILE"

echo "🚀 Subindo Odoo novamente..."
docker compose -f "$COMPOSE_FILE" up -d odoo

echo ""
echo "✅✅ Backup completo finalizado com sucesso!"
echo "📁 Arquivos gerados:"
echo " - Banco: $DUMP_FILE"
echo " - Filestore: $FILESTORE_FILE"
echo ""
