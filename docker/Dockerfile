# Reverse proxy image for docker-compose: nginx with proxy.conf
# baked in (no host bind-mount, so it works regardless of Docker
# Desktop file-sharing settings).
FROM nginx:alpine
COPY proxy.conf /etc/nginx/conf.d/default.conf
