FROM n8nio/n8n:latest

USER root

# Instalamos ffmpeg (para audio), python3 y pip (para yt-dlp)
# Usamos --break-system-packages para permitir instalar yt-dlp globalmente en este entorno aislado
RUN apk add --no-cache ffmpeg python3 py3-pip && \
    pip3 install yt-dlp --break-system-packages

# Volvemos al usuario 'node' por seguridad (como viene por defecto en n8n)
USER node