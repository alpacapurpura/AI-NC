#!/bin/bash

# Script de Validación de Despliegue - Flowise + n8n con Traefik
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
FLOWISE_DOMAIN="${FLOWISE_DOMAIN:-flowise.alpacapurpura.lat}"
N8N_DOMAIN="${N8N_DOMAIN:-n8n.alpacapurpura.lat}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-traefik-unified}"

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar requisitos previos
check_requirements() {
    log_info "Verificando requisitos previos..."
    
    # Verificar Docker
    if ! command_exists docker; then
        log_error "Docker no está instalado"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command_exists docker-compose; then
        log_error "Docker Compose no está instalado"
        exit 1
    fi
    
    # Verificar curl
    if ! command_exists curl; then
        log_error "curl no está instalado"
        exit 1
    fi
    
    log_success "Requisitos previos verificados"
}

# Verificar contenedores Docker
check_containers() {
    log_info "Verificando contenedores Docker..."
    
    # Verificar que todos los servicios estén ejecutándose
    services=("flowise" "postgres-n8n" "qdrant-n8n" "n8n")
    
    for service in "${services[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^${COMPOSE_PROJECT_NAME}_${service}_"; then
            log_success "✓ ${service} está ejecutándose"
        else
            log_error "✗ ${service} no está ejecutándose"
            return 1
        fi
    done
}

# Verificar health checks
check_health() {
    log_info "Verificando health checks..."
    
    # Health check de Flowise
    if docker exec "${COMPOSE_PROJECT_NAME}_flowise_1" curl -f -s "http://localhost:3000/api/v1/health" >/dev/null; then
        log_success "✓ Flowise health check OK"
    else
        log_error "✗ Flowise health check falló"
        return 1
    fi
    
    # Health check de n8n
    if docker exec "${COMPOSE_PROJECT_NAME}_n8n_1" curl -f -s "http://localhost:5678/healthz" >/dev/null; then
        log_success "✓ n8n health check OK"
    else
        log_error "✗ n8n health check falló"
        return 1
    fi
    
    # Health check de PostgreSQL
    if docker exec "${COMPOSE_PROJECT_NAME}_postgres-n8n_1" pg_isready -h localhost -U n8n -d n8n >/dev/null 2>&1; then
        log_success "✓ PostgreSQL health check OK"
    else
        log_error "✗ PostgreSQL health check falló"
        return 1
    fi
    
    # Health check de Qdrant
    if curl -f -s "http://localhost:6333/health" >/dev/null; then
        log_success "✓ Qdrant health check OK"
    else
        log_error "✗ Qdrant health check falló"
        return 1
    fi
}

# Verificar SSL
check_ssl() {
    log_info "Verificando certificados SSL..."
    
    # Verificar SSL de Flowise
    if echo | openssl s_client -connect "${FLOWISE_DOMAIN}:443" -servername "${FLOWISE_DOMAIN}" 2>/dev/null | grep -q "Certificate chain"; then
        log_success "✓ SSL de Flowise OK"
    else
        log_error "✗ SSL de Flowise falló"
        return 1
    fi
    
    # Verificar SSL de n8n
    if echo | openssl s_client -connect "${N8N_DOMAIN}:443" -servername "${N8N_DOMAIN}" 2>/dev/null | grep -q "Certificate chain"; then
        log_success "✓ SSL de n8n OK"
    else
        log_error "✗ SSL de n8n falló"
        return 1
    fi
}

# Verificar acceso web
check_web_access() {
    log_info "Verificando acceso web..."
    
    # Verificar acceso a Flowise
    if curl -f -s -o /dev/null -w "%{http_code}" "https://${FLOWISE_DOMAIN}" | grep -q "200\|302"; then
        log_success "✓ Acceso web a Flowise OK"
    else
        log_error "✗ Acceso web a Flowise falló"
        return 1
    fi
    
    # Verificar acceso a n8n
    if curl -f -s -o /dev/null -w "%{http_code}" "https://${N8N_DOMAIN}" | grep -q "200\|302"; then
        log_success "✓ Acceso web a n8n OK"
    else
        log_error "✗ Acceso web a n8n falló"
        return 1
    fi
}

# Verificar redes Docker
check_networks() {
    log_info "Verificando redes Docker..."
    
    # Verificar red web_network
    if docker network ls | grep -q "web_network"; then
        log_success "✓ Red web_network existe"
    else
        log_error "✗ Red web_network no existe"
        return 1
    fi
    
    # Verificar que contenedores estén en la red correcta
    if docker network inspect web_network | grep -q "${COMPOSE_PROJECT_NAME}_flowise_1"; then
        log_success "✓ Flowise está en web_network"
    else
        log_error "✗ Flowise no está en web_network"
        return 1
    fi
    
    if docker network inspect web_network | grep -q "${COMPOSE_PROJECT_NAME}_n8n_1"; then
        log_success "✓ n8n está en web_network"
    else
        log_error "✗ n8n no está en web_network"
        return 1
    fi
}

# Mostrar información del sistema
show_system_info() {
    log_info "Información del sistema..."
    
    echo ""
    echo "=== INFORMACIÓN DEL SISTEMA ==="
    echo "Fecha: $(date)"
    echo "Docker versión: $(docker --version)"
    echo "Docker Compose versión: $(docker-compose --version)"
    echo "Dominio Flowise: ${FLOWISE_DOMAIN}"
    echo "Dominio n8n: ${N8N_DOMAIN}"
    echo ""
    
    echo "=== ESTADO DE CONTENEDORES ==="
    docker-compose ps
    echo ""
    
    echo "=== ESTADO DE REDES ==="
    docker network ls | grep -E "web_network|services_network"
    echo ""
    
    echo "=== USO DE RECURSOS ==="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Función principal
main() {
    echo ""
    echo "========================================="
    echo "VALIDACIÓN DE DESPLIEGUE - TRAEFIK UNIFIED"
    echo "========================================="
    echo ""
    
    local exit_code=0
    
    # Ejecutar todas las verificaciones
    check_requirements || exit_code=1
    check_networks || exit_code=1
    check_containers || exit_code=1
    check_health || exit_code=1
    check_ssl || exit_code=1
    check_web_access || exit_code=1
    
    # Mostrar información del sistema
    show_system_info
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        log_success "🎉 ¡TODAS LAS VALIDACIONES PASARON!"
        echo ""
        echo "✅ El sistema está correctamente configurado y funcionando."
        echo "✅ Puedes acceder a:"
        echo "   - Flowise: https://${FLOWISE_DOMAIN}"
        echo "   - n8n: https://${N8N_DOMAIN}"
        echo ""
        echo "📚 Documentación adicional en README.md"
    else
        log_error "❌ ALGUNAS VALIDACIONES FALLARON"
        echo ""
        echo "Por favor revisa los logs anteriores para identificar el problema."
        echo "Puedes usar los siguientes comandos para investigar:"
        echo "  - docker-compose logs [servicio]"
        echo "  - docker-compose ps"
        echo "  - docker stats"
    fi
    
    echo ""
    echo "========================================="
    
    exit $exit_code
}

# Ejecutar función principal
main "$@"