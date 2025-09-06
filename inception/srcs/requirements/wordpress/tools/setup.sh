#!/bin/bash

echo "Starting WordPress setup..."

# Set default values
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpassword123}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wpuser}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-wppassword123}

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
for i in {1..60}; do
    if mysqladmin ping -h mariadb -u root -p$MYSQL_ROOT_PASSWORD --silent 2>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "MariaDB connection failed after 60 attempts"
        exit 1
    fi
    echo "Waiting for MariaDB... ($i/60)"
    sleep 2
done

# Test database connection
echo "Testing database connection..."
for i in {1..30}; do
    if mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD -e "USE $MYSQL_DATABASE;" 2>/dev/null; then
        echo "Database connection successful!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Database connection failed after 30 attempts"
        exit 1
    fi
    echo "Waiting for database connection... ($i/30)"
    sleep 2
done

# Ensure WordPress directory exists and has correct permissions
echo "Setting up WordPress directory..."
mkdir -p /var/www/wordpress
chown -R www-data:www-data /var/www/wordpress

# Copy the wp-config.php to the WordPress directory
echo "Copying wp-config.php..."
cp /tmp/wp-config.php /var/www/wordpress/wp-config.php
chown www-data:www-data /var/www/wordpress/wp-config.php

# Download and install WP-CLI
echo "Installing WP-CLI..."
wget https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar
chmod +x wp-cli-2.8.1.phar
mv wp-cli-2.8.1.phar /usr/local/bin/wp

# Change to WordPress directory
cd /var/www/wordpress

# Check if WordPress core files exist
if [ ! -f "wp-load.php" ]; then
    echo "WordPress core files not found, downloading..."
    wp core download --allow-root
fi

# Install WordPress if not already installed
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "Installing WordPress core..."
    wp core install \
        --url="https://ali.42.fr:8443" \
        --title="Ali's WordPress Site" \
        --admin_user="admin" \
        --admin_password="admin123" \
        --admin_email="admin@ali.42.fr" \
        --allow-root \
        --skip-email
    
    echo "WordPress installation completed!"
else
    echo "WordPress already installed!"
fi

# Start PHP-FPM
echo "Starting PHP-FPM..."
php-fpm7.4 --nodaemonize
