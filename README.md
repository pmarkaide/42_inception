<p align="center">
  <img src="https://raw.githubusercontent.com/ayogun/42-project-badges/refs/heads/main/badges/inceptione.png" alt="inception badge">
</p>


## Overview
Inception is a System Administration project at 42 School focused on virtualization using Docker. The project requires setting up a small infrastructure composed of different services under specific rules and using Docker Compose.

The school project must be done inside a Virtual Machine, but you can use the repository code just by using docker inside your OS. That's why we use Docker!

## Requirements

- Docker & Docker Compose
- Make

## Services

The project sets up the following services, each in its own container:

1. **NGINX**: Web server with TLS/SSL
2. **WordPress**: CMS with php-fpm
3. **MariaDB**: Database server

## Project Structure

```
inception/
├── Makefile
├── srcs/
    ├── docker-compose.yml
    ├── .env
    ├── requirements/
        ├── nginx/
            ├── Dockerfile
            ├── conf/
        ├── wordpress/
            ├── Dockerfile
            ├── conf/
        ├── mariadb/
            ├── Dockerfile
            ├── conf/
```

## Setup Instructions

1. Clone the repository
   ```
   git clone https://github.com/your-username/42_inception.git
   cd 42_inception
   ```

2. Create a `.env` file with the following variables and the desired values (NB: **NEVER** upload this file to a public repository):
   ```
    # General Settings
    DOMAIN_NAME=pmarkaide.42.fr
    
    # MariaDB Configuration
    MYSQL_USER=pmarkaide
    MYSQL_PASSWORD=1234
    MYSQL_DATABASE=mariadb
    MYSQL_ROOT_PASSWORD=1234
    
    # WordPress Configuration
    WORDPRESS_TITLE=Inception
    WORDPRESS_ADMIN_USER=Zorg
    WORDPRESS_ADMIN_PASSWORD=1234
    WORDPRESS_ADMIN_EMAIL=Zorg@gmail.com
    WORDPRESS_USER=pmarkaide
    WORDPRESS_PASSWORD=1234
    WORDPRESS_EMAIL=user@gmail.com
   ```

3. Build and start the containers
   ```
   make
   ```

4. Access WordPress at `https://your_domain.42.fr`

## Available Commands

- `make`: Build and start all containers
- `make up`: Start all containers
- `make down`: Stop all containers
- `make clean`: Remove all containers and images
- `make fclean`: Remove all containers, images, and volumes
- `make re`: Rebuild the entire project

## Network Configuration

- All containers are connected to a custom Docker network
- Container ports are not exposed except for NGINX (443)
- NGINX uses TLS/SSL protocol

## Important Notes

- Database data is persisted in a Docker volume
- WordPress files are persisted in a Docker volume

## Troubleshooting

- Check container logs: `docker logs container_name`
- Access a running container: `docker exec -it container_name sh`
- Verify network connectivity: `docker network inspect inception-network`

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [WordPress Installation Guide](https://wordpress.org/support/article/how-to-install-wordpress/)
- [NGINX Configuration Guide](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
