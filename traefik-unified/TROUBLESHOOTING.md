# Troubleshooting: Traefik + Flowise + n8n

Guía práctica para diagnosticar y solucionar problemas comunes: servicios no aparecen en el dashboard de Traefik, errores 404, y certificados SSL.

## Requisitos y contexto
- Traefik corre fuera de este `docker-compose` y expone `web` (80) y `websecure` (443).
- Servicios internos: Flowise (`3000`), n8n (`5678`). No se exponen públicamente; Traefik enruta por dominio.
- Red compartida con Traefik: `web_gateway`.
- Variables en `.env`: `FLOWISE_DOMAIN`, `N8N_DOMAIN`, `LETSENCRYPT_EMAIL`.

---

## 1) Verificar Traefik
- Ver que Traefik esté corriendo:
  - `docker ps | grep traefik`
- Ver logs (errores, routers, ACME):
  - `docker logs traefik --tail=200`
  - `docker logs traefik | grep -i acme`
  - `docker logs traefik | grep -i certificate`
- Confirmar entrypoints (`web`/`websecure`) en configuración estática de Traefik:
  - Busca en el archivo de config de Traefik o revisa los logs al inicio: deben mencionar `web : :80` y `websecure : :443`.
- Confirmar provider Docker habilitado:
  - Los logs deben mencionar `providers.docker` sin errores y los contenedores detectados.

Si Traefik no está en la red correcta o no tiene provider Docker, los servicios no aparecerán en el dashboard.

---

## 2) Verificar DNS y dominios
- Ver que los dominios resuelvan a la IP del servidor:
  - `nslookup $FLOWISE_DOMAIN`
  - `nslookup $N8N_DOMAIN`
- Ver valores configurados en `.env` (desde `traefik-unified`):
  - `grep -E "^(FLOWISE_DOMAIN|N8N_DOMAIN|LETSENCRYPT_EMAIL)=" .env || grep -E "^(FLOWISE_DOMAIN|N8N_DOMAIN|LETSENCRYPT_EMAIL)=" .env.example`
- Si usas Cloudflare, desactiva el proxy naranja (modo directo) para pruebas de emisión de certificados.

Si el dominio no apunta a tu servidor, Traefik devolverá 404 porque la regla `Host(...)` no coincide.

---

## 3) Verificar redes Docker
- Listar redes:
  - `docker network ls | grep -E "web_gateway|services_network"`
- Ver que Traefik esté en `web_gateway`:
  - `docker network inspect web_gateway | grep -i traefik`
  - Si no aparece, conectar:
    - `docker network connect web_gateway traefik`
- Ver que los servicios estén en la red correcta:
  - Flowise: `docker inspect -f '{{json .NetworkSettings.Networks}}' flowise`
  - n8n: `docker inspect -f '{{json .NetworkSettings.Networks}}' n8n`

Si Traefik y los servicios no comparten red, no podrá enrutar y no verás routers en el dashboard.

---

## 4) Verificar labels y routers
- Inspeccionar labels de Flowise:
  - `docker inspect flowise | grep -i traefik`
- Inspeccionar labels de n8n:
  - `docker inspect n8n | grep -i traefik`
- Debes tener al menos:
  - `traefik.enable=true`
  - `traefik.docker.network=web_gateway`
  - Router HTTPS: `traefik.http.routers.<servicio>.entrypoints=websecure`
  - Regla Host: `traefik.http.routers.<servicio>.rule=Host(<tu dominio>)`
  - Puerto interno: `traefik.http.services.<servicio>.loadbalancer.server.port=<puerto>`
  - Redirección HTTP→HTTPS: routers en `web` con middleware `redirect-to-https`.

Si los entrypoints no coinciden con los que usa Traefik, los routers quedan inactivos (404).

---

## 5) Probar conectividad interna
- Healthcheck Flowise desde el contenedor:
  - `docker exec flowise curl -sf http://localhost:3000/ && echo OK || echo FAIL`
- Healthcheck n8n desde el contenedor:
  - `docker exec n8n curl -sf http://localhost:5678/healthz && echo OK || echo FAIL`
- Probar acceso desde el host (si expones los puertos internamente, no requerido):
  - `curl -I https://$FLOWISE_DOMAIN`
  - `curl -I https://$N8N_DOMAIN`

---

## 6) SSL y Let's Encrypt
- Logs de emisión de certificados:
  - `docker logs traefik | grep -i acme`
- Ver que `LETSENCRYPT_EMAIL` esté configurado y dominios resuelvan.
- Si los certificados no se generan:
  - Revisa que Traefik tenga almacenamiento `acme.json` con permisos correctos.
  - Asegura que el puerto 80 (HTTP) esté accesible para los desafíos.

---

## 7) Errores comunes y soluciones
- 404 al acceder por dominio:
  - Dominios no apuntan al servidor → Corrige DNS y espera propagación.
  - EntryPoints diferentes (`web`, `websecure`) en Traefik → Ajusta labels o config de Traefik.
  - Traefik no comparte `web_gateway` con servicios → Conecta Traefik a la red.
  - Regla `Host(...)` no coincide con el dominio → Corrige `.env` y recrea servicios.
- Servicios no aparecen en el dashboard:
  - `providers.docker` deshabilitado o sin acceso al socket Docker → Revisa configuración de Traefik.
  - Faltan labels o están mal escritos → Revisa `docker-compose.yml`.
  - Contenedores no están corriendo/healthy → `docker compose ps` y `docker compose logs`.
- Errores de base de datos (n8n):
  - PostgreSQL no `healthy` → Ver logs de `postgres-n8n`.
  - Variables DB no coinciden → Revisa `.env` y reinicia.

---

## 8) Pasos de recuperación rápida
1. Verifica DNS (`nslookup`) y `.env`.
2. Confirma Traefik corriendo y en `web_gateway`.
3. `cd /home/chris/IA-NC/traefik-unified && docker compose up -d`.
4. `docker compose ps` y `docker compose logs -f flowise n8n`.
5. Prueba healthchecks internos con `docker exec`.
6. Accede por `https://$FLOWISE_DOMAIN` y `https://$N8N_DOMAIN`.

---

## Notas
- En este `docker-compose` ya se añadió redirección HTTP→HTTPS y middlewares de seguridad (HSTS).
- Si tus entrypoints en Traefik tienen nombres distintos a `web`/`websecure`, ajusta las labels en `docker-compose.yml` para coincidir.