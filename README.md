# inception

42 Inception — Debian Starter Kit (VirtualBox)

This is a step‑by‑step path (with ready starter files) to build the mandatory stack for Inception on Debian inside VirtualBox:

Nginx (HTTPS only, self‑signed TLS)

WordPress + PHP‑FPM (separate container, no Apache)

MariaDB (database)

Two persistent volumes on the host: WordPress files & MariaDB data

One internal bridge network via docker compose
Domain name served over HTTPS (mapped in /etc/hosts)

1) Make host directories for persistent data

Create persistent directories on the VM (these will be bind‑mounted inside containers):

mkdir -p /home/ins/data/wordpress
mkdir -p /home/ins/data/mariadb

These survive docker compose down and container rebuilds.

2) Project layout:
    
inception/
└─ srcs/
├─ docker-compose.yml
├─ .env # secrets & config (never push real secrets)
└─ requirements/
├─ nginx/
│ ├─ Dockerfile
│ ├─ conf/nginx.conf
│ └─ tools/gen_cert.sh
├─ mariadb/
│ ├─ Dockerfile
│ ├─ conf/50-server.cnf
│ └─ tools/entrypoint.sh
└─ wordpress/
├─ Dockerfile
├─ conf/php.ini # (optional overrides)
└─ tools/entrypoint.sh

3) .env (single source of truth)

Put this in srcs/.env and edit values (especially passwords & emails):

# Domain & users
DOMAIN_NAME=ins.42.fr
WP_TITLE=Inception Blog
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=StrongAdminPass42!
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author
WP_USER_PASSWORD=StrongUserPass42!
WP_USER_EMAIL=author@example.com


# MariaDB
MYSQL_ROOT_PASSWORD=StrongRootPass42!
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=StrongDBPass42!


# Paths on host (bind mounts)
HOST_WP=/home/ins/data/wordpress
HOST_DB=/home/ins/data/mariadb

Tip: The subject usually forbids committing real secrets. Commit a .env.sample (without secrets) and keep your real .env local.


4) docker-compose.yml

Create srcs/docker-compose.yml:

version: "3.8"
container_name: mariadb
restart: unless-stopped
env_file: .env
volumes:
- mdb_data:/var/lib/mysql
networks:
- inception
expose:
- "3306"
healthcheck:
test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-p${MYSQL_ROOT_PASSWORD}"]
interval: 5s
timeout: 3s
retries: 20


wordpress:
build: ./requirements/wordpress
container_name: wordpress
restart: unless-stopped
env_file: .env
depends_on:
mariadb:
condition: service_healthy
volumes:
- wp_data:/var/www/html
networks:
- inception
expose:
- "9000" # php-fpm


nginx:
build: ./requirements/nginx
container_name: nginx
restart: unless-stopped
env_file: .env
depends_on:
- wordpress
ports:
- "443:443" # HTTPS only (subject requirement)
volumes:
- wp_data:/var/www/html:ro
networks:
- inception


volumes:
mdb_data:
driver: local
driver_opts:
type: none
o: bind
device: ${HOST_DB}
wp_data:
driver: local
driver_opts:
type: none
o: bind
device: ${HOST_WP}


networks:
inception:
driver: bridge



Why:

We build our own images from Dockerfiles (not official service images).

WordPress talks to MariaDB internally; Nginx proxies PHP to the FPM socket on port 9000.

Only Nginx publishes a port (443), keeping DB internal.


5) MariaDB image
requirements/mariadb/Dockerfile

FROM debian:bookworm-slim

RUN apt-get update \
&& apt-get install -y mariadb-server dumb-init \
&& rm -rf /var/lib/apt/lists/*


COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
&& mkdir -p /run/mysqld \
&& chown -R mysql:mysql /run/mysqld /var/lib/mysql


EXPOSE 3306
ENTRYPOINT ["/usr/bin/dumb-init","--"]
CMD ["/usr/local/bin/entrypoint.sh"]


requirements/mariadb/conf/50-server.cnf:

#!/bin/bash
set -euo pipefail


# Ensure ownership on the mounted volume
chown -R mysql:mysql /var/lib/mysql


if [ ! -d "/var/lib/mysql/mysql" ]; then
echo "[MariaDB] First-time init..."
mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null


# Start server without networking for bootstrap
mysqld_safe --skip-networking --socket=/run/mysqld/mysqld.sock &


# Wait for socket
for i in {1..60}; do
if mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then break; fi
sleep 1
done


mysql --socket=/run/mysqld/mysqld.sock <<-SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL


mysqladmin --socket=/run/mysqld/mysqld.sock -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi


exec mysqld_safe


6) WordPress + PHP‑FPM image
requirements/wordpress/Dockerfile


FROM debian:bookworm-slim


RUN apt-get update \
&& apt-get install -y php-fpm php-mysql php-cli curl less tar dumb-init \
&& rm -rf /var/lib/apt/lists/*


# wp-cli
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x /usr/local/bin/wp


# Optional php overrides
COPY conf/php.ini /etc/php/8.2/fpm/php.ini


COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
&& mkdir -p /run/php


WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/bin/dumb-init","--"]
CMD ["/usr/local/bin/entrypoint.sh"]


requirements/wordpress/tools/entrypoint.sh:

#!/bin/bash
set -euo pipefail


# Ensure web root exists and owned by www-data
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html


# Configure php-fpm to listen on TCP 0.0.0.0:9000
PHP_FPM_POOL="/etc/php/8.2/fpm/pool.d/www.conf"
if [ -f "$PHP_FPM_POOL" ]; then
sed -i 's@^listen = .*@listen = 0.0.0.0:9000@' "$PHP_FPM_POOL"
fi


# Wait for DB
until mysqladmin ping -h mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" --silent; do
echo "[WP] Waiting for MariaDB..."; sleep 2; done


# Install WordPress if not present
if [ ! -f wp-config.php ]; then
echo "[WP] Setting up WordPress..."
sudo -u www-data wp core download --path=/var/www/html --allow-root


sudo -u www-data wp config create \
--dbname="$MYSQL_DATABASE" \
--dbuser="$MYSQL_USER" \
--dbpass="$MYSQL_PASSWORD" \
--dbhost="mariadb:3306" \
--path=/var/www/html --skip-check --allow-root


sudo -u www-data wp core install \
--url="https://${DOMAIN_NAME}" \
--title="$WP_TITLE" \
--admin_user="$WP_ADMIN_USER" \
--admin_password="$WP_ADMIN_PASSWORD" \
--admin_email="$WP_ADMIN_EMAIL" \
--skip-email --allow-root


# Optional: create an extra user
sudo -u www-data wp user create "$WP_USER" "$WP_USER_EMAIL" --user_pass="$WP_USER_PASSWORD" --allow-root || true
fi


# Final ownership (in case)
chown -R www-data:www-data /var/www/html


# Run PHP-FPM in foreground
command -v php-fpm8.2 >/dev/null 2>&1 && exec php-fpm8.2 -F || exec php-fpm -F

Why: WordPress installs itself at container start only once (idempotent). PHP‑FPM listens on 0.0.0.0:9000 so Nginx can reach it over the compose network.

7) Nginx image (HTTPS only)
requirements/nginx/Dockerfile

FROM debian:bookworm-slim


RUN apt-get update \
&& apt-get install -y nginx openssl dumb-init \
&& rm -rf /var/lib/apt/lists/*


COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/gen_cert.sh /usr/local/bin/gen_cert.sh
RUN chmod +x /usr/local/bin/gen_cert.sh \
&& mkdir -p /etc/nginx/ssl


EXPOSE 443
ENTRYPOINT ["/usr/bin/dumb-init","--"]
CMD ["/usr/local/bin/gen_cert.sh"]


requirements/nginx/conf/nginx.conf:

user www-data;
worker_processes auto;


error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;


events { worker_connections 1024; }


http {
include /etc/nginx/mime.types;
default_type application/octet-stream;
sendfile on;
keepalive_timeout 65;


server {
listen 443 ssl;
server_name DOMAIN_NAME; # will be replaced at runtime


ssl_certificate /etc/nginx/ssl/server.crt;
ssl_certificate_key /etc/nginx/ssl/server.key;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;


root /var/www/html;
index index.php index.html;


locati






