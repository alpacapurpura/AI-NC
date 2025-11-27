#!/bin/bash
# Script de respaldo para n8n, Flowise y PostgreSQL
# Uso: ./backup.sh

set -e

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
DATA_DIR="./data"

echo "🔄 Creando respaldo en: $BACKUP_DIR"

# Crear directorio de respaldo
mkdir -p "$BACKUP_DIR"

# Respaldar cada servicio
echo "📦 Respaldando Flowise..."
tar -czf "$BACKUP_DIR/flowise-data.tar.gz" -C "$DATA_DIR" flowise 2>/dev/null || echo "⚠️  Flowise no tiene datos aún"

echo "📦 Respaldando n8n..."
tar -czf "$BACKUP_DIR/n8n-data.tar.gz" -C "$DATA_DIR" n8n 2>/dev/null || echo "⚠️  n8n no tiene datos aún"

echo "📦 Respaldando PostgreSQL..."
tar -czf "$BACKUP_DIR/postgres-data.tar.gz" -C "$DATA_DIR" postgres 2>/dev/null || echo "⚠️  PostgreSQL no tiene datos aún"

echo "✅ Respaldo completado en: $BACKUP_DIR"
echo ""
echo "📊 Tamaño del respaldo:"
du -sh "$BACKUP_DIR"

# Limpiar respaldos antiguos (mantener solo los últimos 7)
echo ""
echo "🧹 Limpiando respaldos antiguos (manteniendo últimos 7)..."
ls -dt ./backups/*/ | tail -n +8 | xargs rm -rf 2>/dev/null || true
echo "✅ Limpieza completada"
