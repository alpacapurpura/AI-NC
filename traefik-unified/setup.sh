#!/bin/bash

# Script de Configuración Inicial - Traefik Unified Deployment
# Autor: Sistema Automatizado Alpaca Purpura
# Versión: 1.0

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables de configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE_FILE="${SCRIPT_DIR}/.env.example"

# Función para generar claves seguras
generate_secure_key() {
    openssl rand -base64 32 2>/dev/null || date | md5sum | head -c 32
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar requisitos del sistema
check_system_requirements() {
    log_info "Verificando requisitos del sistema..."
    
    # Verificar sistema operativo
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_warning "Este script está optimizado para Linux. Continuando de todos modos..."
    fi
    
    # Verificar arquitectura
    if [[ "$(uname -m)" != "x86_64" ]]; then
        log_warning "Arquitectura no x86_64 detectada. Algunas imágenes podrían no ser compatibles."
    fi
    
    # Verificar memoria RAM
    total_memory=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_memory -lt 4096 ]]; then
        log_warning "Memoria insuficiente (${total_memory}MB). Se recomiendan al menos 4GB."
    else
        log_success "Memoria suficiente: ${total_memory}MB"
    fi
    
    # Verificar espacio en disco
    available_space=$(df -BG "${SCRIPT_DIR}" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -lt 20 ]]; then
        log_warning "Espacio en disco insuficiente (${available_space}GB). Se recomiendan al menos 20GB."
    else
        log_success "Espacio en disco suficiente: ${available_space}GB"
    fi
}

# Verificar Docker y Docker Compose
check_docker() {
    log_info "Verificando Docker y Docker Compose..."
    
    if ! command_exists docker; then
        log_error "Docker no está instalado. Por favor instala Docker primero."
        echo "Instrucciones: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        log_error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
        echo "Instrucciones: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Verificar que Docker esté ejecutándose
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker no está ejecutándose. Por favor inicia el servicio Docker."
        exit 1
    fi
    
    log_success "Docker y Docker Compose están correctamente instalados"
}

# Verificar Traefik y red web_network
check_traefik() {
    log_info "Verificando Traefik y red web_network..."
    
    # Verificar que la red web_network existe
    if ! docker network ls | grep -q "web_network"; then
        log_error "La red 'web_network' no existe. Por favor crea la red primero:"
        echo "  docker network create web_network"
        exit 1
    fi
    
    # Verificar que Traefik esté ejecutándose (opcional pero recomendado)
    if ! docker ps --format "table {{.Names}}" | grep -q "traefik"; then
        log_warning "Traefik no parece estar ejecutándose. Asegúrate de que esté configurado correctamente."
    else
        log_success "Traefik detectado en el sistema"
    fi
}

# Crear archivo de entorno si no existe
create_env_file() {
    log_info "Configurando archivo de entorno..."
    
    if [[ -f "$ENV_FILE" ]]; then
        log_warning "El archivo .env ya existe. ¿Deseas sobrescribirlo? (s/N)"
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            log_info "Conservando archivo .env existente"
            return 0
        fi
    fi
    
    # Generar claves seguras
    log_info "Generando claves seguras..."
    flowise_secret=$(generate_secure_key)
    n8n_encryption_key=$(generate_secure_key)
    n8n_jwt_secret=$(generate_secure_key)
    postgres_password=$(generate_secure_key | tr -d '=+/')
    
    # Crear archivo .env
    cat > "$ENV_FILE" << EOF
# ==============================================
# CONFIGURACIÓN GLOBAL - TRAEFIK UNIFIED DEPLOY
# ==============================================

# Dominios configurados
FLOWISE_DOMAIN=flowise.alpacapurpura.lat
N8N_DOMAIN=n8n.alpacapurpura.lat

# Email para Let's Encrypt SSL
LETSENCRYPT_EMAIL=alpacapurpura@gmail.com

# ==============================================
# CONFIGURACIÓN DE FLOWISE
# ==============================================

# Credenciales de acceso a Flowise
FLOWISE_USERNAME=alpacapurpura
FLOWISE_PASSWORD=alpacapurpura123

# Clave secreta para Flowise
FLOWISE_SECRET_KEY=${flowise_secret}

# ==============================================
# CONFIGURACIÓN DE N8N
# ==============================================

# Configuración de PostgreSQL
POSTGRES_USER=n8n
POSTGRES_PASSWORD=${postgres_password}
POSTGRES_DB=n8n

# Claves de seguridad para n8n
N8N_ENCRYPTION_KEY=${n8n_encryption_key}
N8N_USER_MANAGEMENT_JWT_SECRET=${n8n_jwt_secret}

# Configuración de zona horaria
TZ=America/Lima
EOF
    
    log_success "Archivo .env creado con claves seguras generadas automáticamente"
}

# Crear directorios necesarios
create_directories() {
    log_info "Creando directorios necesarios..."
    
    directories=(
        "backups"
        "logs"
        "data/flowise"
        "data/n8n"
        "data/postgres"
        "data/qdrant"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Directorio creado: $dir"
        else
            log_info "Directorio ya existe: $dir"
        fi
    done
}

# Verificar y sugerir cambios en el archivo .env
review_env_file() {
    log_info "Revisando configuración..."
    
    # Verificar que las claves no sean las de ejemplo
    if grep -q "alpacapurpura123" "$ENV_FILE"; then
        log_warning "Se detectó la contraseña por defecto. Considera cambiarla."
    fi
    
    if grep -q "alpacapurpura@gmail.com" "$ENV_FILE"; then
        log_warning "Se detectó el email por defecto. Actualízalo con tu email real."
    fi
    
    # Mostrar resumen de configuración
    echo ""
    echo "=== RESUMEN DE CONFIGURACIÓN ==="
    echo "Dominio Flowise: $(grep FLOWISE_DOMAIN "$ENV_FILE" | cut -d'=' -f2)"
    echo "Dominio n8n: $(grep N8N_DOMAIN "$ENV_FILE" | cut -d'=' -f2)"
    echo "Usuario Flowise: $(grep FLOWISE_USERNAME "$ENV_FILE" | cut -d'=' -f2)"
    echo "Email SSL: $(grep LETSENCRYPT_EMAIL "$ENV_FILE" | cut -d'=' -f2)"
    echo ""
}

# Descargar imágenes Docker con antelación
pull_images() {
    log_info "Descargando imágenes Docker..."
    
    images=(
        "flowiseai/flowise:latest"
        "n8nio/n8n:latest"
        "postgres:16-alpine"
        "qdrant/qdrant:latest"
    )
    
    for image in "${images[@]}"; do
        log_info "Descargando $image..."
        if docker pull "$image"; then
            log_success "✓ $image descargada"
        else
            log_error "✗ Error descargando $image"
            return 1
        fi
    done
}

# Validar configuración de dominios
validate_domains() {
    log_info "Validando configuración de dominios..."
    
    flowise_domain=$(grep FLOWISE_DOMAIN "$ENV_FILE" | cut -d'=' -f2)
    n8n_domain=$(grep N8N_DOMAIN "$ENV_FILE" | cut -d'=' -f2)
    
    log_info "Dominios configurados:"
    echo "  - Flowise: $flowise_domain"
    echo "  - n8n: $n8n_domain"
    
    log_warning "Asegúrate de que estos dominios apunten a la IP de este servidor"
    log_warning "Puedes verificarlo con: nslookup $flowise_domain"
}

# Crear script de backup
create_backup_script() {
    log_info "Creando script de backup..."
    
    cat > "${SCRIPT_DIR}/backup.sh" << 'EOF'
#!/bin/bash

# Script de Backup - Traefik Unified Deployment
# Autor: Sistema Automatizado Alpaca Purpura

set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "Iniciando backup..."

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

# Backup de volúmenes Docker
echo "Creando backups de volúmenes..."

docker run --rm -v traefik-unified_flowise_data:/source:ro -v "$BACKUP_DIR":/backup alpine tar czf "/backup/flowise_backup_${DATE}.tar.gz" -C /source .
docker run --rm -v traefik-unified_n8n_data:/source:ro -v "$BACKUP_DIR":/backup alpine tar czf "/backup/n8n_backup_${DATE}.tar.gz" -C /source .
docker run --rm -v traefik-unified_postgres_data:/source:ro -v "$BACKUP_DIR":/backup alpine tar czf "/backup/postgres_backup_${DATE}.tar.gz" -C /source .
docker run --rm -v traefik-unified_qdrant_data:/source:ro -v "$BACKUP_DIR":/backup alpine tar czf "/backup/qdrant_backup_${DATE}.tar.gz" -C /source .

echo "Backup completado: $BACKUP_DIR/backup_${DATE}"
EOF
    
    chmod +x "${SCRIPT_DIR}/backup.sh"
    log_success "Script de backup creado: backup.sh"
}

# Función principal
main() {
    echo ""
    echo "========================================="
    echo "CONFIGURACIÓN INICIAL - TRAEFIK UNIFIED"
    echo "========================================="
    echo ""
    
    # Ejecutar todas las verificaciones y configuraciones
    check_system_requirements
    check_docker
    check_traefik
    create_env_file
    create_directories
    review_env_file
    
    # Opciones adicionales
    echo ""
    echo "¿Deseas descargar las imágenes Docker ahora? (recomendado) [S/n]"
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        pull_images
    fi
    
    validate_domains
    create_backup_script
    
    echo ""
    log_success "🎉 CONFIGURACIÓN INICIAL COMPLETADA"
    echo ""
    echo "=== SIGUIENTES PASOS ==="
    echo "1. Revisa y actualiza el archivo .env con tus valores reales"
    echo "2. Asegúrate de que los dominios apunten a este servidor"
    echo "3. Ejecuta: docker-compose up -d"
    echo "4. Ejecuta: ./validate-deployment.sh para verificar"
    echo ""
    echo "=== COMANDOS ÚTILES ==="
    echo "- Ver logs: docker-compose logs -f"
    echo "- Ver estado: docker-compose ps"
    echo "- Backup: ./backup.sh"
    echo "- Validar: ./validate-deployment.sh"
    echo ""
    echo "📚 Lee README.md para más información"
    echo ""
    echo "========================================="
}

# Ejecutar función principal
main "$@"