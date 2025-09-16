#!/bin/sh

# Read the password from the Docker secret file
DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d "/var/lib/mariadb/mariadb" ]; then
  echo "Initializing database..."
  mariadb-install-db --user=root --basedir=/usr --datadir=/var/lib/mysql
  echo "Setting up database and users..."
  mariadbd --user=root --bootstrap <<EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY '$DB_PASSWORD';
CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
EOF
else
  echo "Database already initialized."
fi

exec "$@"