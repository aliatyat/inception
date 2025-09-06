FROM debian:bullseye

# Install MariaDB server
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy MariaDB configuration
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create directories and set permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# Create log directory
RUN mkdir -p /var/log/mysql && \
    chown -R mysql:mysql /var/log/mysql

# Expose MariaDB port
EXPOSE 3306

# Use custom entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld", "--user=mysql"]
