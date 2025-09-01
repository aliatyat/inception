#!/bin/bash

set -e # Exit the script if fails

# Function to check if database is already init

if [ -z "$(ls -A /var/lib/mysql/mysql)"]; then
	echo "Initializing MariaDB database for the first time"


# Init the MariaDB data dir and system tables
mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db > /dev/null

# Start MariaDB temporarily in the background to run setup command 
mysql --datadir=/var/lib/mysql --socket=/var/run/mysqld/mysql.sock --skip-networing --nowatch > /dev/null 2>&1 &

# Wait for the temporary MariaDB server to start and be ready for connections
while ! mysqladmin ping --silent --socket=/var/run/mysqld/mysql.sock; do
	sleep 1
done

# Run the SQL commands to secure the installation and create the WordPress setup.
  # All values are pulled from the environment variables set by Docker Compose.
  mysql --socket=/var/run/mysqld/mysqld.sock -uroot <<-EOF
    -- Set the root password (from the .env file, MANDATORY for security)
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    -- Remove remote root user for security
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

    -- Remove anonymous users and the test database (Standard security practice)
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

    -- Create the WordPress database (name from .env)
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

    -- Create the WordPress user (from .env) and grant privileges
    -- The '%' allows connection from any host inside the Docker network
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

    -- Apply the privilege changes
    FLUSH PRIVILEGES;
EOF

# Shut down the temporary MariaDB instance
mysqladmin --socket=/var/run/mysqld/mtsql.sock -uroot -p${MYSQL_ROOT_PASSOWRD} 
shutdown

	echo "MariaDB init complete"
fi

# Start MariaDB in the foreground this is the main process that keeps the container alive. This against "hacky patches" like 'tail -f'
echo "Start MariaDB server..."
exec mysqld --datadir=/var/lib/mysql
