# Use a lightweight base image suitable for Raspberry Pi (adjust if needed, e.g., arm64v8/nginx)
FROM nginx:stable-alpine

# Install openssl for certificate generation and apache2-utils for htpasswd
RUN apk update && apk add --no-cache openssl apache2-utils

# Create necessary directories (though volumes will mostly handle this)
RUN mkdir -p /etc/nginx/ssl /var/log/nginx /usr/share/nginx/html/data

# Copy the entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy the Nginx configuration (optional here, as it's mounted via volume, but good for context)
# COPY default.conf /etc/nginx/conf.d/default.conf

# Expose ports (mostly informational as docker-compose handles mapping)
EXPOSE 80 443

# The entrypoint script will handle setup and then run the Nginx command
# ENTRYPOINT ["/entrypoint.sh"] # Set in docker-compose.yml
# CMD ["nginx", "-g", "daemon off;"] # Set as 'command' in docker-compose.yml