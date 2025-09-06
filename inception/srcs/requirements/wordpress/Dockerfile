FROM debian:bullseye

# Install necessary packages
RUN apt-get update && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    wget \
    unzip \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Download and install WordPress
RUN wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /tmp && \
    mkdir -p /var/www/html && \
    mv /tmp/wordpress/* /var/www/html/ && \
    rm -rf /tmp/wordpress.tar.gz /tmp/wordpress

# Create tools directory and copy setup script
RUN mkdir -p /tmp/tools
COPY tools/setup.sh /tmp/tools/setup.sh
COPY conf/wp-config.php /tmp/wp-config.php

# Make setup script executable
RUN chmod +x /tmp/tools/setup.sh

# Configure PHP-FPM to listen on 0.0.0.0:9000
RUN mkdir -p /run/php && \
    sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

CMD ["/tmp/tools/setup.sh"]
