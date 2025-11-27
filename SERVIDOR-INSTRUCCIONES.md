# 🚀 INSTRUCCIONES RÁPIDAS PARA EL SERVIDOR

## ⚡ Resumen Ejecutivo

Se ha migrado de **named volumes** a **bind mounts** para evitar pérdida de datos al actualizar.

### 📍 Cambios Realizados

✅ `docker-compose.yml` actualizado para usar `./data/` en lugar de volúmenes Docker  
✅ Script de respaldo `backup.sh` creado  
✅ Documentación completa en `MIGRATION_GUIDE.md` y `UPDATE_GUIDE.md`

---

## 🎯 PASOS A SEGUIR EN EL SERVIDOR

### 1️⃣ Hacer Pull del Código

```bash
cd /ruta/a/IA-NC
git pull origin main
```

### 2️⃣ Detener Servicios

```bash
# SIN el flag -v
docker compose --profile flowise --profile n8n down
```

### 3️⃣ Crear Directorios

```bash
mkdir -p ./data/{flowise,n8n,postgres}
chmod -R 775 ./data
```

### 4️⃣ Levantar Servicios

```bash
docker compose pull
docker compose --profile flowise --profile n8n up -d
```

### 5️⃣ Verificar

```bash
# Ver servicios
docker compose ps

# Ver que los datos se están almacenando
ls -lah ./data/flowise/
ls -lah ./data/n8n/
ls -lah ./data/postgres/

# Ver logs
docker compose logs -f n8n
```

---

## 🔄 Actualizaciones Futuras

```bash
# Proceso simple para actualizar n8n o Flowise:
./backup.sh                                    # Backup preventivo
docker compose pull                            # Descargar nuevas versiones
docker compose --profile flowise --profile n8n up -d  # Aplicar
```

**⚠️ IMPORTANTE**: NUNCA uses `docker compose down -v` (aunque ahora con bind mounts tus datos estarían seguros)

---

## 📚 Documentación Completa

- **Migración**: `MIGRATION_GUIDE.md` - Guía paso a paso completa
- **Actualizaciones**: `UPDATE_GUIDE.md` - Cómo actualizar n8n/Flowise
- **Respaldo**: `./backup.sh` - Script de backup automático

---

## ✅ Checklist de Validación Post-Migración

- [ ] Servicios corriendo: `docker compose ps`
- [ ] Directorios con datos: `ls ./data/*/`
- [ ] Flowise accesible: `https://flowise.alpacapurpura.lat`
- [ ] n8n accesible: `https://n8n.alpacapurpura.lat`
- [ ] Crear flujo de prueba en n8n
- [ ] Ejecutar backup: `./backup.sh`

---

## 🆘 Si Algo Sale Mal

```bash
# Ver logs detallados
docker compose logs -f

# Reiniciar un servicio específico
docker compose restart n8n

# Recrear todo (datos permanecen seguros)
docker compose down
docker compose up -d --force-recreate
```

---

## 📊 Antes vs Ahora

| Acción | Antes (Named Volumes) | Ahora (Bind Mounts) |
|--------|----------------------|---------------------|
| `down -v` | ❌ Perdías todo | ✅ Datos seguros en `./data/` |
| Actualizar | Complejo | Simple: `pull` + `up -d` |
| Backup | Difícil | Fácil: `./backup.sh` |
| Migración | Imposible | Fácil: copiar `./data/` |

---

**🎉 Beneficio Principal**: Nunca más perderás tus flujos al actualizar n8n o Flowise.
