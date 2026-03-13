FROM nginx:alpine

# Copiar build web para nginx
COPY build/web /usr/share/nginx/html

# Configuração nginx para Flutter web (SPA routing)
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    add_header Access-Control-Allow-Origin "*"; \
    add_header X-Frame-Options "ALLOWALL"; \
    gzip on; \
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript; \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
