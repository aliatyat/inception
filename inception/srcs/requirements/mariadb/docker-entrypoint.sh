#!/bin/bash

set -e  # Exit immediately if any command fails

# Set default values if environment variables are not set
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpassword123}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wpuser}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-wppassword123}

echo "Using database: $MYSQL_DATABASE"
echo "Using user: $MYSQL_USER"

# Initialize database if not exists
# Check if the mysql system database directory exists
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    
    # Install the MariaDB system databases
    # --user=mysql: Run as mysql user for security
    # --datadir: Specify where to create the database files
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MariaDB in safe mode for initialization
    # --skip-networking: Don't listen on network during init (security)
    # & : Run in background so we can continue with setup
    mysqld_safe --datadir=/var/lib/mysql --user=mysql --skip-networking &
    MYSQL_PID=$!  # Store the process ID for later cleanup
    
    # Wait for MySQL to start - Critical for avoiding connection errors
    echo "Waiting for MariaDB to start..."
    for i in {1..30}; do  # Try up to 30 times (60 seconds total)
        if mysqladmin ping --silent; then  # Test if MariaDB is responding
            echo "MariaDB is running!"
            break
        fi
        echo "Waiting for MariaDB... ($i/30)"
        sleep 2  # Wait 2 seconds between attempts
    done
    
    echo "Creating database and user..."
    
    # Create database and user using HERE document
    # This prevents "Access denied" errors by setting up proper permissions
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'wppassword123';
CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppassword123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'wpuser'@'%' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('rootpassword123');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
EOF

    echo "MariaDB initialization completed!"
    
    # Stop the temporary server cleanly
    kill $MYSQL_PID     # Send termination signal
    wait $MYSQL_PID     # Wait for process to fully stop
fi

# Start MariaDB normally for production use
# exec replaces the shell process with MariaDB (proper Docker pattern)
echo "Starting MariaDB..."
exec "$@"  # Execute the command passed to the container (usually mysqld)