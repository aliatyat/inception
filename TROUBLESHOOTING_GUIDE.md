# Inception Project - Troubleshooting Guide & Commands

## Project Overview
This Docker-based project creates a WordPress website with MariaDB and Nginx using custom domain `yourlogin.42.fr` with SSL certificates.

## Architecture
- **MariaDB Container**: Database server (port 3306)
- **WordPress Container**: PHP-FPM application server (port 9000)
- **Nginx Container**: Web server with SSL termination (ports 80 → 443/8443)

---

## Essential Docker Commands

### 1. Container Management
```bash
# Start all containers
docker-compose up -d
# Comment: Starts all services in detached mode (background)

# Stop all containers
docker-compose down
# Comment: Stops and removes all containers and networks

# View running containers
docker ps
# Comment: Shows status of all running containers

# View container logs
docker logs <container_name>
# Comment: Shows real-time logs for debugging issues

# Execute commands inside container
docker exec -it <container_name> bash
# Comment: Opens interactive shell inside container for debugging
```

### 2. Network Debugging Commands
```bash
# Test container connectivity
docker exec nginx ping wordpress
# Comment: Tests if nginx can reach wordpress container on network

# Check listening ports in container
docker exec wordpress netstat -tuln
# Comment: Shows what ports are listening inside container

# Test FastCGI connection
docker exec nginx telnet wordpress 9000
# Comment: Tests if nginx can connect to PHP-FPM port
```

### 3. Service Status Commands
```bash
# Check PHP-FPM processes
docker exec wordpress ps aux | grep php-fpm
# Comment: Verifies PHP-FPM master and worker processes are running

# Check MariaDB service
docker exec mariadb mysqladmin ping -u root -p
# Comment: Tests if MariaDB server is responding

# Check Nginx configuration syntax
docker exec nginx nginx -t
# Comment: Validates nginx.conf syntax before restart
```

### 4. Log Analysis Commands
```bash
# Check Nginx error logs
docker exec nginx tail -f /var/log/nginx/error.log
# Comment: Shows real-time nginx errors for debugging 502/500 errors

# Check PHP-FPM logs
docker exec wordpress tail -f /var/log/php7.4-fpm.log
# Comment: Shows PHP-FPM errors and connection issues

# Check container startup logs
docker-compose logs wordpress
# Comment: Shows container initialization logs for startup issues
```

### 5. Testing Commands
```bash
# Test HTTPS website
curl -k https://ali.42.fr:8443
# Comment: Tests SSL website (-k ignores certificate warnings)

# Test HTTP redirect
curl -I http://ali.42.fr:8080
# Comment: Tests if HTTP properly redirects to HTTPS (should return 301)

# Test website response code only
curl -k -s -o /dev/null -w "%{http_code}\n" https://ali.42.fr:8443
# Comment: Returns only HTTP status code for quick testing
```

---

## Problems Faced & Solutions

### Problem 1: Initial 500 Internal Server Error
**Symptoms:**
- Website returned HTTP 500 error
- Nginx couldn't connect to WordPress

**Root Cause:**
- Missing docker-compose.yml dependencies
- Containers starting in wrong order
- Missing environment variables

**Solution:**
```yaml
# Added proper service dependencies in docker-compose.yml
services:
  wordpress:
    depends_on:
      - mariadb
  nginx:
    depends_on:
      - wordpress
```

**Key Commands Used:**
```bash
docker-compose logs wordpress  # Found missing database connection
docker exec wordpress env      # Checked environment variables
```

---

### Problem 2: Database Connection Failed
**Symptoms:**
- WordPress couldn't connect to MariaDB
- "Error establishing database connection"

**Root Cause:**
- MariaDB not properly initialized
- Wrong database credentials
- Network connectivity issues

**Solution:**
```bash
# Fixed MariaDB initialization script
# Added proper environment variables
# Created WordPress database and user manually

# Verification commands:
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
docker exec mariadb mysql -u wpuser -p wordpress -e "SELECT 1;"
```

---

### Problem 3: Port Conflicts
**Symptoms:**
- Containers failing to start
- Port already in use errors

**Root Cause:**
- Host ports 80/443 already occupied
- Conflicting services on host

**Solution:**
```yaml
# Changed to custom ports in docker-compose.yml
ports:
  - "8080:80"   # HTTP redirect
  - "8443:443"  # HTTPS main site
```

**Verification:**
```bash
netstat -tuln | grep ":8080\|:8443"  # Check if ports are free
```

---

### Problem 4: SSL Certificate Issues
**Symptoms:**
- SSL/TLS handshake failures
- Certificate not found errors

**Root Cause:**
- Wrong certificate paths in nginx.conf
- Certificate files not mounted properly

**Solution:**
```nginx
# Fixed certificate paths in nginx.conf
ssl_certificate /etc/nginx/ssl/user.42.fr.crt;
ssl_certificate_key /etc/nginx/ssl/user.42.fr.key;
```

**Verification:**
```bash
docker exec nginx ls -la /etc/nginx/ssl/  # Check certificate files exist
openssl x509 -in /path/to/cert.crt -text -noout  # Verify certificate
```

---

### Problem 5: FastCGI Communication Failure (502 Bad Gateway)
**Symptoms:**
- Nginx returns 502 Bad Gateway
- "Connection reset by peer" in logs
- PHP-FPM processes running but not accessible

**Root Cause:**
- PHP-FPM listening only on localhost (127.0.0.1:9000)
- Should listen on all interfaces (0.0.0.0:9000)

**Solution:**
```bash
# Fixed PHP-FPM configuration
docker exec wordpress sed -i 's/^listen = 9000/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Commented out restrictive allowed_clients
docker exec wordpress sed -i 's/^listen.allowed_clients = 0.0.0.0/;listen.allowed_clients = 127.0.0.1/' /etc/php/7.4/fpm/pool.d/www.conf

# Restart PHP-FPM
docker exec wordpress service php7.4-fpm restart
```

**Diagnostic Commands:**
```bash
# Check PHP-FPM configuration
docker exec wordpress cat /etc/php/7.4/fpm/pool.d/www.conf | grep -E "listen|pm\."

# Test PHP-FPM syntax
docker exec wordpress php-fpm7.4 -t

# Check if PHP-FPM is listening on correct interface
docker exec wordpress netstat -tuln | grep :9000
```

---

### Problem 5: 502 Bad Gateway Error (CRITICAL ISSUE)
**Symptoms:**
- Nginx returns HTTP 502 "Bad Gateway"
- Error logs show "recv() failed (104: Connection reset by peer)"
- Website completely inaccessible
- PHP-FPM processes running but not reachable

**Root Cause:**
- PHP-FPM listening only on `localhost` (127.0.0.1:9000) inside container
- Nginx in separate container cannot reach localhost of WordPress container
- Network communication failure between containers

**Diagnostic Commands:**
```bash
# Check what interface PHP-FPM is listening on
docker exec wordpress netstat -tuln | grep :9000

# Test connection from nginx to wordpress
docker exec nginx telnet wordpress 9000

# Check nginx error logs
docker exec nginx tail -f /var/log/nginx/error.log

# Verify PHP-FPM configuration
docker exec wordpress cat /etc/php/7.4/fpm/pool.d/www.conf | grep "listen"
```

**Solution:**
```bash
# CRITICAL FIX: Change PHP-FPM to listen on all interfaces
docker exec wordpress sed -i 's/^listen = 9000/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Remove client restrictions (optional but recommended)
docker exec wordpress sed -i 's/^listen.allowed_clients = 0.0.0.0/;listen.allowed_clients = 127.0.0.1/' /etc/php/7.4/fpm/pool.d/www.conf

# Restart PHP-FPM to apply changes
docker exec wordpress service php7.4-fpm restart

# Test the fix
curl -k -s -o /dev/null -w "%{http_code}\n" https://ali.42.fr:8443
```

**Why This Worked:**
- `listen = 9000` binds to localhost only (127.0.0.1:9000)
- `listen = 0.0.0.0:9000` binds to all network interfaces
- Allows nginx container to reach PHP-FPM across Docker network

---

### Problem 6: 403 Forbidden Error
**Symptoms:**
- Website returns HTTP 403 "Forbidden"
- "Access denied" in nginx logs
- Directory browsing blocked

**Root Cause:**
- Wrong file permissions on WordPress files
- Nginx user cannot read WordPress files
- Missing index files or wrong directory permissions

**Diagnostic Commands:**
```bash
# Check file permissions
docker exec wordpress ls -la /var/www/wordpress/

# Check nginx user
docker exec nginx whoami

# Check if index.php exists
docker exec wordpress ls -la /var/www/wordpress/index.php

# Check nginx error logs for permission errors
docker exec nginx grep "Permission denied" /var/log/nginx/error.log
```

**Solution:**
```bash
# Fix file ownership
docker exec wordpress chown -R www-data:www-data /var/www/wordpress/

# Fix file permissions
docker exec wordpress find /var/www/wordpress/ -type f -exec chmod 644 {} \;
docker exec wordpress find /var/www/wordpress/ -type d -exec chmod 755 {} \;

# Ensure index.php exists and is readable
docker exec wordpress ls -la /var/www/wordpress/index.php

# Restart nginx
docker restart nginx
```

---

### Problem 7: 401 Unauthorized Error
**Symptoms:**
- HTTP 401 "Unauthorized" response
- Authentication required errors
- Database connection issues

**Root Cause:**
- Wrong database credentials in wp-config.php
- MariaDB user permissions not set correctly
- Database not accessible from WordPress container

**Diagnostic Commands:**
```bash
# Test database connection from WordPress container
docker exec wordpress mysql -h mariadb -u wpuser -p wordpress -e "SELECT 1;"

# Check WordPress database configuration
docker exec wordpress grep "DB_" /var/www/wordpress/wp-config.php

# Check MariaDB users and permissions
docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"
docker exec mariadb mysql -u root -p -e "SHOW GRANTS FOR 'wpuser'@'%';"
```

**Solution:**
```bash
# Recreate database user with correct permissions
docker exec mariadb mysql -u root -p << EOF
DROP USER IF EXISTS 'wpuser'@'%';
CREATE USER 'wpuser'@'%' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
EOF

# Update wp-config.php with correct credentials
docker exec wordpress sed -i "s/define('DB_USER', '.*');/define('DB_USER', 'wpuser');/" /var/www/wordpress/wp-config.php
docker exec wordpress sed -i "s/define('DB_PASSWORD', '.*');/define('DB_PASSWORD', 'your_password');/" /var/www/wordpress/wp-config.php

# Test the connection
docker exec wordpress mysql -h mariadb -u wpuser -p wordpress -e "SELECT 1;"
```

---

### Problem 6: Volume Mounting Issues
**Symptoms:**
- WordPress files not persisting
- Permission denied errors
- Empty directories in containers

**Root Cause:**
- Wrong volume paths
- Permission mismatches
- Missing directory creation

**Solution:**
```yaml
# Fixed volume mounting in docker-compose.yml
volumes:
  - wordpress_data:/var/www/wordpress
  - mariadb_data:/var/lib/mysql

volumes:
  wordpress_data:
    driver: local
  mariadb_data:
    driver: local
```

**Verification:**
```bash
docker volume ls                           # List all volumes
docker exec wordpress ls -la /var/www/    # Check WordPress files
docker exec wordpress whoami              # Check user permissions
```

---

## Critical Configuration Files

### 1. PHP-FPM Pool Configuration
**File:** `/etc/php/7.4/fpm/pool.d/www.conf`
**Critical Settings:**
```ini
listen = 0.0.0.0:9000          # Listen on all interfaces
;listen.allowed_clients =       # Allow all connections
pm.max_children = 5            # Process management
pm.start_servers = 2
```

### 2. Nginx FastCGI Configuration
**File:** `/etc/nginx/conf.d/default.conf`
**Critical Block:**
```nginx
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_pass wordpress:9000;           # Container name and port
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

### 3. WordPress Configuration
**File:** `/var/www/wordpress/wp-config.php`
**Critical Settings:**
```php
define('DB_HOST', 'mariadb:3306');        # Container name
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('WP_HOME', 'https://ali.42.fr:8443');
define('WP_SITEURL', 'https://ali.42.fr:8443');
```

---

## Final Testing Checklist

### 1. Container Health
```bash
docker ps                                  # All containers running
docker-compose logs | grep -i error       # No critical errors
```

### 2. Network Connectivity
```bash
docker exec nginx ping wordpress           # Network communication
docker exec wordpress ping mariadb        # Database connectivity
```

### 3. Service Functionality
```bash
curl -k https://ali.42.fr:8443           # Website loads (200 OK)
curl -I http://ali.42.fr:8080            # HTTP redirects (301)
```

### 4. Database Access
```bash
docker exec mariadb mysql -u wpuser -p wordpress -e "SELECT 1;"  # DB access works
```

---

## Performance Monitoring Commands

```bash
# Monitor container resource usage
docker stats

# Check container disk usage
docker system df

# Monitor real-time logs
docker-compose logs -f

# Check specific container resource usage
docker exec <container> top
```

---

## Backup & Maintenance Commands

```bash
# Backup WordPress files
docker cp wordpress:/var/www/wordpress ./backup/

# Backup database
docker exec mariadb mysqldump -u root -p wordpress > backup.sql

# Clean unused Docker resources
docker system prune -a

# Update containers (rebuild)
docker-compose build --no-cache
docker-compose up -d
```

---

## HTTP Error Codes Quick Reference

### 🔴 502 Bad Gateway
**Most Common Error in This Project**
- **Meaning**: Nginx cannot communicate with PHP-FPM
- **Quick Test**: `curl -k -s -o /dev/null -w "%{http_code}\n" https://ali.42.fr:8443`
- **Quick Fix**: Change PHP-FPM listen to `0.0.0.0:9000`
- **Debug**: Check nginx error logs for "Connection reset by peer"

### 🟠 403 Forbidden  
**File Permission Issues**
- **Meaning**: Nginx cannot read WordPress files
- **Quick Test**: `docker exec nginx ls -la /var/www/wordpress/`
- **Quick Fix**: Fix file permissions with `chown` and `chmod`
- **Debug**: Check if www-data user can access files

### 🟡 401 Unauthorized
**Database Authentication Issues**
- **Meaning**: WordPress cannot authenticate with MariaDB
- **Quick Test**: `docker exec wordpress mysql -h mariadb -u wpuser -p`
- **Quick Fix**: Recreate database user and permissions
- **Debug**: Check wp-config.php credentials

### 🟢 200 OK
**Everything Working!**
- **Meaning**: Website is functioning correctly
- **Test**: `curl -k https://ali.42.fr:8443`

### 🔵 301 Moved Permanently
**HTTP Redirect Working**
- **Meaning**: HTTP properly redirects to HTTPS
- **Test**: `curl -I http://ali.42.fr:8080`

---

## Error Resolution Flowchart

```
Website not working?
├── 502 Bad Gateway?
│   ├── Check PHP-FPM listening address
│   ├── Fix: listen = 0.0.0.0:9000
│   └── Restart PHP-FPM service
├── 403 Forbidden?
│   ├── Check file permissions
│   ├── Fix: chown www-data:www-data
│   └── Fix: chmod 644/755
├── 401 Unauthorized?
│   ├── Check database connection
│   ├── Fix: Recreate DB user
│   └── Fix: Update wp-config.php
├── 500 Internal Server Error?
│   ├── Check container dependencies
│   ├── Check environment variables
│   └── Check container startup order
└── Container won't start?
    ├── Check port conflicts
    ├── Check volume mounting
    └── Check Dockerfile syntax
```

---

## Key Lessons Learned

1. **Container Communication**: Always use container names in configuration files, not localhost
2. **PHP-FPM Networking**: Must listen on `0.0.0.0:9000` for inter-container communication
3. **Volume Persistence**: Use named volumes for data that needs to persist
4. **Service Dependencies**: Proper `depends_on` order prevents startup race conditions
5. **Log Analysis**: Always check logs systematically (nginx → php-fpm → mariadb)
6. **Network Testing**: Use `ping` and `telnet` to verify container connectivity
7. **Configuration Testing**: Always test config syntax before restarting services

## Final Architecture Status
✅ **MariaDB**: Running on port 3306, WordPress database created
✅ **WordPress**: PHP-FPM listening on 0.0.0.0:9000, site installed
✅ **Nginx**: SSL enabled, FastCGI working, redirects configured
✅ **Domain**: https://ali.42.fr:8443 fully functional
✅ **Security**: SSL certificates, hidden files blocked, proper permissions
