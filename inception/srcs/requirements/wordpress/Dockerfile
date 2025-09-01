# Use the penultimate stable Debian
FROM debian:bookworm-slim

# Install PHP-FPM and necessary extensions for WordPress
RUN apt-get update && \
    apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create the WordPress directory
RUN mkdir -p /var/www/html

# Copy custom PHP-FPM configuration
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy WordPress installation script
COPY tools/entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/setup.sh

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM in the foreground
CMD ["php-fpm8.2", "-F"]
