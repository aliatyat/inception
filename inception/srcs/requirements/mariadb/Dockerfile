FROM debian:bookworm-slim

# Install MariaDB, the client, and some basic tools
# mariadb-server: The MariaDB database server
# mariadb-client: The client tools (needed for the init scribt)
# bash: To run the shell script

RUN apt-get update \
&& apt-get install -y mariadb-server maria-client \
bash \
&& rm -f /var/lib/apt/lists/*

# Create the directory for MariaDB data and set correct ownership

RUN mkdir -p /var/lib/mysql
RUN chmod -R mysql:mysql /var/lib/mysql

# Copy custom configuration and init script into the image

COPY conf/my_config.cnf /etc/mysql/my_config.cnf
COPY tools/entrypoint.sh /tmp/entrypoint.sh

# Make init script executable

RUN chmod +x /tmp/entrypoint.sh

# Expose the default MariaDB port (For internal container communication)
EXPOSE 3306

# Define a volume for presistent data (The actual mount is in docker-compose.yml)
VOLUME /var/lib/mysql

# The command to run when the container start it executes the custom script
CMD ["bash", "/tmp/entrypoint.sh"]

