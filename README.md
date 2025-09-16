# Inception Project - Complete Summary & Troubleshooting Guide

## 🎯 **Project Overview**

The Inception project is a Docker-based infrastructure setup that deploys a complete LEMP stack (Linux, Nginx, MariaDB, PHP) with WordPress using Docker Compose. The project creates a containerized environment with custom domain SSL support.

### **Final Working Configuration:**
- **Domain**: https://yourlogin.42.fr 
- **Architecture**: 3 separate Docker containers
- **Services**: MariaDB 10.5, WordPress with PHP-FPM 7.4, Nginx 1.21
- **SSL**: Self-signed certificates for HTTPS
- **Network**: Custom Docker bridge network
- **Volumes**: Persistent data storage for database and WordPress files

---

## 🏗️ **Project Architecture**

### **Container Structure:**

1. **MariaDB Container (`mariadb`)**
   - **Base Image**: `debian:bullseye`
   - **Purpose**: Database server for WordPress
   - **Port**: 3306 (internal)
   - **Volume**: `mariadb_data:/var/lib/mysql`
   - **Configuration**: Custom `my.cnf` with optimized settings

2. **WordPress Container (`wordpress`)**
   - **Base Image**: `debian:bullseye`
   - **Purpose**: PHP-FPM application server with WordPress
   - **Port**: 9000 (internal FastCGI)
   - **Volume**: `wordpress_data:/var/www/wordpress`
   - **Features**: WP-CLI, PHP 7.4-FPM, automated WordPress installation

3. **Nginx Container (`nginx`)**
   - **Base Image**: `debian:bullseye`
   - **Purpose**: Web server and reverse proxy
   - **Port**: 443 (HTTPS)
   - **Volume**: Shared `wordpress_data` for file access
   - **Features**: SSL termination, FastCGI proxy to WordPress

### **Network Flow:**
```
Internet → Nginx:443 (SSL) → WordPress:9000 (FastCGI) → MariaDB:3306
```

---

## 🚨 **Major Issues Encountered & Solutions**

### **1. Initial 500 Internal Server Error**
**Problem**: WordPress returning 500 error on initial access
**Root Cause**: Missing WordPress core files in container
**Solution**: 
- Fixed WordPress Dockerfile to properly download and extract WordPress
- Added WP-CLI for automated WordPress management
- Ensured proper file permissions (www-data:www-data)

### **2. Database Connection Failures**
**Problem**: WordPress couldn't connect to MariaDB
**Root Causes**: 
- MariaDB initialization script not running properly
- Database and user not created
- Host-based connection restrictions

**Solutions Applied**:
```bash
# Manually created database and user
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'%' IDENTIFIED BY 'wppasswor';
CREATE USER 'wpuser'@'wordpress.srcs_inception' IDENTIFIED BY 'wppassword';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'wordpress.srcs_inception';
FLUSH PRIVILEGES;
```

### **3. Volume Mounting Conflicts**
**Problem**: Docker volumes hiding container files during development
**Solution**: Temporarily removed volume mounting during container building phase, then re-enabled for production

### **4. Port 443 Conflicts**
**Problem**: System already using port 443. This is common if you have another web server (like Apache, another Nginx, or other services) running on your machine.
**Solution**:
Stop the service using port 443
 First, find what's using port 443:

  bash$ sudo netstat -tulpn | grep :443
  bash$ sudo lsof -i :443

If it's Apache or another web server, you can stop it:

  # Stop Apache (if running)
  bash$ sudo systemctl stop apache2

  # Or stop other web servers
  bash$ sudo systemctl stop nginx


### **5. Domain Resolution Issues**
**Problem**: Custom domain not resolving
**Solution**: Added to `/etc/hosts`:
```bash
127.0.0.1 yourlogin.42.fr
```

### **6. Critical: 502 Bad Gateway (Final Challenge)**
**Problem**: Nginx returning 502 errors when communicating with PHP-FPM
**Root Cause**: PHP-FPM configured to listen only on localhost instead of all interfaces
**Solution**:
```bash
# In PHP-FPM pool configuration
# Changed from: listen = 9000 
# To: listen = 0.0.0.0:9000
```

This was the critical fix that resolved container-to-container communication.

---

## 🔧 **Key Configuration Files**

### **Docker Compose Structure**
```yaml
services:
  service1:
    build: ../requirements/service1
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
    volumes:
      - service1_data:/var/lib/mysql

  service2:
    build: ../requirements/service2
    depends_on: [service1]
    volumes:
      - service2_data:/var/www/wordpress

  service3:
    build: ../requirements/service3
    ports:
      - "443:443"
    depends_on: [service2]
    volumes:
      - service2_data:/var/www/wordpress
```

### **Critical PHP-FPM Configuration**
```bash
# /etc/php/7.4/fpm/pool.d/www.conf
listen = 0.0.0.0:9000  # CRITICAL: Must listen on all interfaces
listen.owner = www-data
listen.group = www-data
```

### **Nginx FastCGI Configuration**
```nginx
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_pass wordpress:9000;  # Container-to-container communication
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

---

## 🔄 **How The Project Works**

### **Container Startup Sequence**:

1. **MariaDB Container Starts**
   - Runs initialization script if database doesn't exist
   - Creates WordPress database and user
   - Starts MariaDB daemon on port 3306

2. **WordPress Container Starts** (waits for MariaDB)
   - Downloads WordPress core files using WP-CLI
   - Creates wp-config.php with database credentials
   - Installs WordPress via WP-CLI
   - Starts PHP-FPM daemon listening on all interfaces (0.0.0.0:9000)

3. **Nginx Container Starts** (waits for WordPress)
   - Loads SSL certificates
   - Configures reverse proxy to WordPress container
   - Starts nginx daemon on port 443

### **Request Processing Flow**:

1. **HTTPS Request**: `https://yourlogin.42.fr/`
2. **SSL Termination**: Nginx decrypts SSL
3. **Routing**: Nginx determines if request needs PHP processing
4. **FastCGI**: For .php files, nginx forwards to `wordpress:9000`
5. **PHP Processing**: WordPress container processes PHP via PHP-FPM
6. **Database**: WordPress queries MariaDB if needed
7. **Response**: HTML returned through nginx to client

### **Data Persistence**:
- **MariaDB Data**: Stored in `mariadb_data` volume
- **WordPress Files**: Stored in `wordpress_data` volume
- **Shared Access**: Nginx and WordPress both mount wordpress_data volume

---

## 🛠️ **Troubleshooting Commands Used**

### **Container Management**:
```bash
# Clean restart
make fclean && make up

# Check container status
docker ps

# View logs
docker logs [container_name]
docker-compose logs [service_name]

# Execute commands in containers
docker exec [container] [command]
```

### **Database Debugging**:
```bash
# Check databases
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Check users
docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"

# Test connection from WordPress
docker exec wordpress mysql -h mariadb -u wpuser -p -e "SHOW DATABASES;"
```

### **Network Debugging**:
```bash
# Check listening ports
docker exec wordpress cat /proc/net/tcp

# Check PHP-FPM processes
docker exec wordpress ps aux | grep php

# Check nginx configuration
docker exec nginx nginx -t
```

### **File System Debugging**:
```bash
# Check WordPress files
docker exec wordpress ls -la /var/www/wordpress/

# Check permissions
docker exec wordpress ls -la /var/www/

# Check nginx can access files
docker exec nginx ls -la /var/www/wordpress/
```

---

## ✅ **Final Working State**

### **Access Information**:
- **Website URL**: https://yourlogin.42.fr
- **WordPress Admin**: https://yourlogin.42.fr/wp-admin
  - Username: `adminusername`
  - Password: `adminpassword`
  - Email: `admin@yourlogin.42.fr`

### **Environment Variables** (`.env`):
```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword

# WordPress Configuration
DOMAIN_NAME=yourlogin.42.fr
WP_TITLE=yourlogin WordPress Site
WP_ADMIN_USR=adminusername
WP_ADMIN_PWD=adminpassword
WP_ADMIN_EMAIL=admin@yourlogin.42.fr
```

### **Container Status** (All Running):
```bash
CONTAINER ID   IMAGE            COMMAND                  STATUS         PORTS
nginx          srcs-nginx       "nginx -g 'daemon of…"   Up X minutes   0.0.0.0:443->443/tcp
wordpress      srcs-wordpress   "/tmp/setup.sh"          Up X minutes   9000/tcp
mariadb        srcs-mariadb     "docker-entrypoint.s…"   Up X minutes   3306/tcp
```

---

## 🎓 **Key Lessons Learned**

1. **Container Communication**: Inter-container communication requires services to listen on all interfaces (0.0.0.0), not just localhost
2. **Dependency Management**: Proper service dependencies and health checks are crucial
3. **Volume Strategy**: Separate build and runtime phases when using volumes
4. **Network Debugging**: Use container names for internal communication, not IPs
5. **Configuration Testing**: Always test configurations incrementally
6. **Log Analysis**: Container logs are essential for debugging complex issues

### **Best Practices Implemented**:
- ✅ Separate concerns (database, application, web server)
- ✅ Persistent data storage with volumes
- ✅ Environment variable configuration
- ✅ SSL/TLS encryption
- ✅ Proper file permissions and ownership
- ✅ Health checks and dependencies
- ✅ Minimal container images with specific purposes

---

## 🚀 **Project Success Metrics**

- **Containerization**: ✅ 3 properly isolated containers
- **Networking**: ✅ Custom Docker network with container communication
- **Persistence**: ✅ Data survives container restarts
- **Security**: ✅ SSL encryption and proper user permissions
- **Automation**: ✅ Fully automated deployment with single command
- **WordPress**: ✅ Fully functional WordPress installation
- **Domain**: ✅ Custom domain with SSL certificate

**The Inception project is now successfully deployed and fully operational!** 🎉

---

*Project Status: ✅ COMPLETE AND WORKING*
