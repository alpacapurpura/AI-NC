# Docker Compose Profiles - Guía de Uso

Este docker-compose.yml está configurado con **profiles separados** para ejecutar los servicios de forma independiente.

## Profiles Disponibles

### 📊 Profile: `flowise`
- **Servicios incluidos**: `flowise`
- **Puerto**: 3000
- **Dominio**: `${FLOWISE_DOMAIN}`

### 🔄 Profile: `n8n`
- **Servicios incluidos**: `n8n`, `postgres`
- **Puerto**: 5678
- **Dominio**: `${N8N_DOMAIN}`

---

## Comandos de Uso

### 1. Levantar SOLO Flowise

```bash
docker-compose --profile flowise up -d
```

**Resultado**: Solo se ejecutará el servicio `flowise`

### 2. Levantar SOLO n8n (con PostgreSQL)

```bash
docker-compose --profile n8n up -d
```

**Resultado**: Se ejecutarán los servicios `n8n` y `postgres`

### 3. Levantar AMBOS entornos

```bash
docker-compose --profile flowise --profile n8n up -d
```

**Resultado**: Se ejecutarán todos los servicios: `flowise`, `n8n` y `postgres`

### 4. Ver logs por profile

```bash
# Solo Flowise
docker-compose --profile flowise logs -f

# Solo n8n
docker-compose --profile n8n logs -f

# Ambos
docker-compose --profile flowise --profile n8n logs -f
```

### 5. Detener servicios por profile

```bash
# Detener solo Flowise
docker-compose --profile flowise down

# Detener solo n8n
docker-compose --profile n8n down

# Detener todos
docker-compose --profile flowise --profile n8n down
```

### 6. Verificar estado

```bash
# Ver servicios de Flowise
docker-compose --profile flowise ps

# Ver servicios de n8n
docker-compose --profile n8n ps

# Ver todos los servicios
docker-compose --profile flowise --profile n8n ps
```

---

## Ejemplos de Uso Práctico

### Escenario 1: Desarrollo local de Flowise

```bash
# Levantar solo Flowise para trabajar en flujos de IA
docker-compose --profile flowise up -d

# Ver logs en tiempo real
docker-compose --profile flowise logs -f flowise

# Cuando termines
docker-compose --profile flowise down
```

### Escenario 2: Desarrollo local de n8n

```bash
# Levantar n8n con su base de datos
docker-compose --profile n8n up -d

# Acceder a n8n en http://localhost:5678 (o el dominio configurado)
# Ver logs
docker-compose --profile n8n logs -f n8n

# Cuando termines
docker-compose --profile n8n down
```

### Escenario 3: Producción completa

```bash
# Levantar todo el stack
docker-compose --profile flowise --profile n8n up -d

# Verificar que todo está corriendo
docker-compose --profile flowise --profile n8n ps

# Monitorear todos los logs
docker-compose --profile flowise --profile n8n logs -f
```

---

## Ventajas de usar Profiles

✅ **Ahorro de recursos**: Ejecuta solo lo que necesitas  
✅ **Desarrollo independiente**: Trabaja en Flowise sin levantar n8n y viceversa  
✅ **Testing aislado**: Prueba cada servicio de forma independiente  
✅ **Despliegues flexibles**: Despliega solo lo necesario en cada servidor  
✅ **Debugging más fácil**: Logs y troubleshooting más enfocados  

---

## Variables de Entorno Necesarias

### Para profile `flowise`:
```bash
FLOWISE_DOMAIN=flowise.tudominio.com
FLOWISE_USERNAME=tu_usuario
FLOWISE_PASSWORD=tu_contraseña
FLOWISE_SECRET_KEY=tu_clave_secreta
```

### Para profile `n8n`:
```bash
N8N_DOMAIN=n8n.tudominio.com
N8N_PROTOCOL=https
POSTGRES_USER=n8n
POSTGRES_PASSWORD=tu_contraseña_postgres
POSTGRES_DB=n8n
N8N_ENCRYPTION_KEY=tu_clave_encriptacion
N8N_USER_MANAGEMENT_JWT_SECRET=tu_jwt_secret
```

---

## Troubleshooting

### Problema: "No services selected"
**Solución**: Debes especificar al menos un profile con `--profile <nombre>`

### Problema: n8n no conecta a la base de datos
**Solución**: Asegúrate de levantar el profile completo `--profile n8n` que incluye postgres

### Problema: Quiero levantar todo sin especificar profiles
**Opción 1**: Usar `--profile flowise --profile n8n`  
**Opción 2**: Crear un alias en tu `.bashrc`:
```bash
alias dc-all='docker-compose --profile flowise --profile n8n'
```

---

## Accesos

- **Flowise**: https://flowise.alpacapurpura.lat
- **n8n**: https://n8n.alpacapurpura.lat

**Nota**: Asegúrate de que Traefik esté corriendo y la red `web_gateway` exista antes de levantar los servicios.
