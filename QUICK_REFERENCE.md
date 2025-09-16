# Quick Reference - Essential Commands

## 🚀 Start/Stop Project
```bash
# Start everything
docker-compose up -d

# Stop everything  
docker-compose down

# Restart with rebuild
docker-compose down && docker-compose up -d --build
```

## 🔍 Quick Debugging
```bash
# Check if website is working
curl -k -s -o /dev/null -w "%{http_code}\n" https://yourlogin.42.fr

# Check container status
docker ps

# Check recent errors
docker-compose logs --tail=50 | grep -i error
```

## 🩺 Deep Diagnostics
```bash
# Check PHP-FPM status
docker exec wordpress ps aux | grep php-fpm

# Check nginx-to-wordpress connection
docker exec nginx ping wordpress

# Check PHP-FPM listen address
docker exec wordpress netstat -tuln | grep :9000

# View real-time nginx errors
docker exec nginx tail -f /var/log/nginx/error.log
```

## 🔧 Common Fixes

### 502 Bad Gateway (MOST COMMON)
```bash
# Fix PHP-FPM listening (if 502 errors)
docker exec wordpress sed -i 's/^listen = 9000/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf
docker exec wordpress service php7.4-fpm restart

# Verify the fix
curl -k -s -o /dev/null -w "%{http_code}\n" https://yourlogin.42.fr:8443
```

### 403 Forbidden Errors
```bash
# Fix file permissions
docker exec wordpress chown -R www-data:www-data /var/www/wordpress/
docker exec wordpress find /var/www/wordpress/ -type f -exec chmod 644 {} \;
docker exec wordpress find /var/www/wordpress/ -type d -exec chmod 755 {} \;
```

### 401 Unauthorized / Database Issues
```bash
# Test database connection
docker exec wordpress mysql -h mariadb -u wpuser -p wordpress -e "SELECT 1;"

# Check database user permissions
docker exec mariadb mysql -u root -p -e "SHOW GRANTS FOR 'wpuser'@'%';"

# Recreate database user if needed
docker exec mariadb mysql -u root -p -e "
DROP USER IF EXISTS 'wpuser'@'%';
CREATE USER 'wpuser'@'%' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;"
```

### General Debugging
```bash
# Test nginx config
docker exec nginx nginx -t

# Check database connection
docker exec mariadb mysql -u wpuser -p wordpress -e "SELECT 1;"
```

## 🌐 Website Testing
```bash
# Test HTTPS (should return 200)
curl -k https://yourlogin.42.fr:8443

# Test HTTP redirect (should return 301)  
curl -I http://yourlogin.42.fr

# Get first few lines of website
curl -k https://yourlogin.42.fr 2>/dev/null | head -5
```

## 🛠️ The Magic Fix That Solved 502 Errors
```bash
# This was the KEY command that fixed our 502 Bad Gateway:
docker exec wordpress sed -i 's/^listen = 9000/listen = 0.0.0.0:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Why: PHP-FPM was only listening on localhost, nginx couldn't reach it from another container
```
