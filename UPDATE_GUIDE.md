# Guía de Actualización de n8n y Flowise

## 🔄 Proceso de Actualización

### Actualización Estándar (Recomendada)

```bash
# 1. Hacer backup preventivo (opcional pero recomendado)
./backup.sh

# 2. Hacer pull de las nuevas imágenes Docker
docker compose pull

# 3. Recrear y reiniciar los contenedores con las nuevas imágenes
docker compose --profile flowise --profile n8n up -d

# 4. Verificar que todo funciona correctamente
docker compose ps
docker compose logs -f n8n
```

### Actualización Forzada (Si la estándar no funciona)

```bash
# 1. Backup
./backup.sh

# 2. Detener servicios (SIN -v)
docker compose --profile flowise --profile n8n down

# 3. Limpiar imágenes antiguas
docker compose pull

# 4. Recrear contenedores desde cero
docker compose --profile flowise --profile n8n up -d --force-recreate

# 5. Verificar versiones
docker compose exec n8n n8n --version
```

### En Caso de Emergencia (Limpieza completa)

```bash
# ⚠️ SOLO usar si algo está muy mal y tienes un backup

# 1. Asegurar que tienes backup
ls -lah ./backups/

# 2. Detener TODO
docker compose --profile flowise --profile n8n down

# 3. Limpiar contenedores, imágenes y cache de Docker
docker system prune -a

# 4. Hacer pull limpio
docker compose pull

# 5. Reiniciar servicios
docker compose --profile flowise --profile n8n up -d
```

---

## ✅ Verificar Versiones

```bash
# Ver versión de n8n
docker compose exec n8n n8n --version

# Ver imágenes actuales
docker compose images

# Ver última versión disponible de n8n
curl -s https://api.github.com/repos/n8n-io/n8n/releases/latest | grep tag_name
```

---

## 🛡️ Comandos Seguros vs Peligrosos

### ✅ Comandos SEGUROS (No pierdes datos)

```bash
docker compose down                    # Detiene pero NO borra datos
docker compose pull                    # Descarga nuevas versiones
docker compose up -d                   # Inicia con nuevas versiones
docker compose up -d --force-recreate  # Fuerza recreación
docker compose restart                 # Reinicia servicios
```

### ❌ Comandos PELIGROSOS (Evitar)

```bash
docker compose down -v                 # ❌ BORRA VOLÚMENES (ya no aplica con bind mounts)
docker system prune --volumes          # ❌ Puede afectar otros proyectos
rm -rf ./data                          # ❌ NUNCA hacer esto
```

---

## 📝 Notas Importantes

1. **Tus datos están seguros**: Con bind mounts en `./data/`, tus flujos persisten aunque hagas `down -v`
2. **No necesitas `-v`**: Ya no es necesario usar el flag `-v` para actualizar
3. **Backup regular**: Ejecuta `./backup.sh` antes de actualizaciones importantes
4. **Monitorea logs**: Siempre revisa logs después de actualizar

---

## 🔧 Troubleshooting de Actualizaciones

### Problema: "La nueva versión no se refleja"

```bash
# Forzar descarga de imágenes
docker compose pull

# Verificar que descargó nueva imagen
docker compose images n8n

# Recrear contenedor
docker compose up -d --force-recreate n8n
```

### Problema: "Errores después de actualizar"

```bash
# Ver logs en tiempo real
docker compose logs -f n8n

# Volver a versión anterior (si es necesario)
# Editar docker-compose.yml y cambiar:
# image: n8nio/n8n:latest  →  image: n8nio/n8n:1.15.0

docker compose up -d --force-recreate n8n
```

### Problema: "Base de datos incompatible"

```bash
# n8n hace migraciones automáticas
# Si falla, restaurar backup:

docker compose down
tar -xzf ./backups/FECHA/postgres-data.tar.gz -C ./data/
docker compose up -d
```
