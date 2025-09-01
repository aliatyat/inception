# Use the penultimate stable Debian
FROM debian:bookworm-slim

# Install nginx and openssl for SSL certificates
RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# Create directory for nginx PID file
RUN mkdir -p /run/nginx

# Generate SSL certificate (using domain from build args)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=localhost"

# Copy custom nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Expose port 443 (HTTPS)
EXPOSE 443

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
