# Despliegue Unificado: Flowise + n8n con Traefik

Sistema de despliegue unificado para Flowise AI y n8n utilizando Traefik como proxy inverso con SSL automático.

## 📋 Requisitos Previos

### Hardware Mínimo
- **CPU**: 2 cores
- **RAM**: 4GB (8GB+ recomendado)
- **Almacenamiento**: 20GB+ disponibles
- **Red**: Conexión a internet estable

### Software Requerido
- Docker Engine 20.10+
- Docker Compose 2.0+
- Traefik 2.9+ previamente configurado
- Sistema operativo Linux (Ubuntu 20.04+ recomendado)

### Dominios y DNS
- `flowise.alpacapurpura.lat` apuntando al servidor
- `n8n.alpacapurpura.lat` apuntando al servidor
- Ambos dominios deben resolver correctamente

## 🚀 Instalación Rápida

### 1. Verificar Traefik
```bash
# Verificar que Traefik está ejecutándose
docker ps | grep traefik

# Verificar que la red web_network existe
docker network ls | grep web_network
```

### 2. Clonar y Configurar
```bash
# Clonar el repositorio (si aplica)
git clone [URL_DEL_REPOSITORIO]
cd traefik-unified

# Copiar archivo de entorno
cp .env.example .env

# Editar configuración
nano .env
```

### 3. Configurar Variables de Entorno
Editar el archivo `.env` con tus valores:

```bash
# Dominios
FLOWISE_DOMAIN=flowise.alpacapurpura.lat
N8N_DOMAIN=n8n.alpacapurpura.lat

# Email para SSL
LETSENCRYPT_EMAIL=alpacapurpura@gmail.com

# Credenciales Flowise
FLOWISE_USERNAME=tu_usuario
FLOWISE_PASSWORD=tu_contraseña_segura

# Credenciales n8n/PostgreSQL
POSTGRES_PASSWORD=tu_contraseña_postgres_segura
N8N_ENCRYPTION_KEY=tu_clave_de_encriptacion_muy_larga
N8N_USER_MANAGEMENT_JWT_SECRET=tu_jwt_secret_muy_largo
```

### 4. Desplegar Servicios
```bash
# Desplegar todos los servicios
docker-compose up -d

# Verificar estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

## 🔧 Configuración Detallada

### Variables de Entorno Importantes

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `FLOWISE_DOMAIN` | Dominio para Flowise | `flowise.alpacapurpura.lat` |
| `N8N_DOMAIN` | Dominio para n8n | `n8n.alpacapurpura.lat` |
| `LETSENCRYPT_EMAIL` | Email para certificados SSL | `alpacapurpura@gmail.com` |
| `FLOWISE_USERNAME` | Usuario de Flowise | `alpacapurpura` |
| `FLOWISE_PASSWORD` | Contraseña de Flowise | `alpacapurpura123` |

### Redes Docker

- **web_network**: Red externa para comunicación con Traefik
- **services_network**: Red interna para comunicación entre servicios

### Puertos Expuestos

| Servicio | Puerto Interno | Puerto Externo | Descripción |
|----------|---------------|----------------|-------------|
| Flowise | 3000 | - | A través de Traefik |
| n8n | 5678 | - | A través de Traefik |
| PostgreSQL | 5432 | - | Solo red interna |
| Qdrant | 6333 | 6333 | Acceso directo para desarrollo |

## ✅ Verificación del Despliegue

### 1. Verificar Contenedores
```bash
# Todos los servicios deben estar "Up"
docker-compose ps

# Ver logs si hay problemas
docker-compose logs [nombre-servicio]
```

### 2. Verificar SSL
```bash
# Probar conexión SSL
curl -I https://flowise.alpacapurpura.lat
curl -I https://n8n.alpacapurpura.lat

# Verificar certificado (debe ser válido)
openssl s_client -connect flowise.alpacapurpura.lat:443 -servername flowise.alpacapurpura.lat
```

### 3. Verificar Health Checks
```bash
# Flowise
curl -f http://localhost:3000/api/v1/health

# n8n
curl -f http://localhost:5678/healthz

# Qdrant
curl -f http://localhost:6333/health
```

### 4. Acceder a Interfaces Web

- **Flowise**: https://flowise.alpacapurpura.lat
- **n8n**: https://n8n.alpacapurpura.lat

## 📊 Monitoreo y Mantenimiento

### Ver Logs en Tiempo Real
```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f flowise
docker-compose logs -f n8n
```

### Actualizar Servicios
```bash
# Detener servicios
docker-compose down

# Actualizar imágenes
docker-compose pull

# Volver a desplegar
docker-compose up -d
```

### Backup de Datos
```bash
# Crear backup de todos los volúmenes
docker run --rm -v flowise_data:/source:ro -v $(pwd)/backups:/backup alpine tar czf /backup/flowise_backup_$(date +%Y%m%d).tar.gz -C /source .
docker run --rm -v n8n_data:/source:ro -v $(pwd)/backups:/backup alpine tar czf /backup/n8n_backup_$(date +%Y%m%d).tar.gz -C /source .
docker run --rm -v postgres_data:/source:ro -v $(pwd)/backups:/backup alpine tar czf /backup/postgres_backup_$(date +%Y%m%d).tar.gz -C /source .
```

## 🔍 Solución de Problemas

### Problemas Comunes

#### 1. SSL No Funciona
```bash
# Verificar que dominios resuelven correctamente
nslookup flowise.alpacapurpura.lat
nslookup n8n.alpacapurpura.lat

# Verificar logs de Traefik
docker logs traefik
```

#### 2. Servicios No Inician
```bash
# Verificar logs específicos
docker-compose logs [nombre-servicio]

# Verificar recursos disponibles
docker system df
docker stats
```

#### 3. Conexión a Base de Datos Falla
```bash
# Verificar que PostgreSQL está healthy
docker-compose ps postgres

# Ver logs de PostgreSQL
docker-compose logs postgres
```

#### 4. Problemas de Red
```bash
# Verificar redes
docker network ls
docker network inspect web_network
docker network inspect traefik-unified_services_network
```

### Comandos de Diagnóstico

```bash
# Estado general
docker-compose ps

# Uso de recursos
docker stats

# Logs recientes
docker-compose logs --tail=50

# Reiniciar servicio específico
docker-compose restart [nombre-servicio]

# Acceder a contenedor
docker-compose exec [nombre-servicio] bash
```

## 🛡️ Seguridad

### Recomendaciones de Seguridad

1. **Cambiar contraseñas por defecto inmediatamente**
2. **Usar claves de encriptación fuertes y únicas**
3. **Configurar firewall para permitir solo puertos necesarios**
4. **Habilitar logs de auditoría**
5. **Realizar backups regulares**
6. **Mantener servicios actualizados**

### Firewall (UFW)
```bash
# Permitir SSH
sudo ufw allow 22/tcp

# Permitir HTTP/HTTPS (Traefik los maneja)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Habilitar firewall
sudo ufw enable
```

## 📚 Referencias

- [Documentación de Flowise](https://docs.flowiseai.com/)
- [Documentación de n8n](https://docs.n8n.io/)
- [Documentación de Traefik](https://doc.traefik.io/traefik/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Soporte

Para problemas o preguntas:
1. Verificar logs primero
2. Consultar documentación oficial de cada servicio
3. Revisar configuración de red y DNS
4. Verificar recursos del sistema

---

**⚡ Desplegado con Docker + Traefik + Let's Encrypt**