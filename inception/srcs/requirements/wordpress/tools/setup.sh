#!/bin/bash

echo "Starting WordPress setup..."

# Read passwords from Docker secret files
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_password)
WP_PWD=$(cat /run/secrets/wp_user_password)

# Set other variables from environment
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpassword123}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wpuser}

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
        --url="https://alalauty.42.fr" \
        --title="Ali's WordPress Site" \
        --admin_user="$WP_ADMIN_USR" \
        --admin_password="$WP_ADMIN_PWD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root \
        --skip-email \
        # Create additional user if needed
    if [ ! -z "$WP_USR" ]; then
        echo "Creating additional user..."
        wp user create "$WP_USR" "$WP_EMAIL" --user_pass="$WP_PWD" --role="subscriber" --allow-root
    fi
    
    echo "WordPress installation completed!"
else
    echo "WordPress already installed!"
fi

# Start PHP-FPM
echo "Starting PHP-FPM..."
php-fpm7.4 --nodaemonize