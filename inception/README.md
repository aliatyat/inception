# Inception (42 School)

This project sets up a secure, multi-container Docker infrastructure with Nginx, WordPress, and MariaDB using Docker Compose. Only the mandatory part is implemented here.

## Services
- **Nginx**: Serves as a reverse proxy with SSL.
- **WordPress**: PHP-based CMS.
- **MariaDB**: Database for WordPress.

## Usage
1. Copy the repository.
2. Run `docker-compose up --build` from the `srcs` directory.
3. Access WordPress at https://localhost (accept the self-signed certificate).

## Volumes
- Data for MariaDB and WordPress is persisted using Docker volumes.

## Environment Variables
See `.env` for credentials and configuration.

---

This setup is for educational purposes and follows the 42 School Inception project mandatory requirements.
