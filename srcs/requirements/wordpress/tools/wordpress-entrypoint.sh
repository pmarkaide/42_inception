#!/bin/bash
set -e

# Increase PHP memory limit for WP-CLI
export WP_CLI_PHP_ARGS='-d memory_limit=512M'

cd /var/www/html

# Configure PHP-FPM on the first run
if [ ! -e /etc/.firstrun ]; then
    echo "Setting up wordpress for the first time..."
    # Make sure PHP-FPM is properly configured
    sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php82/php-fpm.d/www.conf
    # Preserve environment variables from the parent process
    sed -i 's/;clear_env = no/clear_env = no/g' /etc/php82/php-fpm.d/www.conf

    # increase memory
    mkdir -p /etc/php82/conf.d/ && \
    echo "memory_limit = 512M" > /etc/php82/conf.d/99_memory.ini

    touch /etc/.firstrun
fi

# On the first volume mount, download and configure WordPress
if [ ! -e .firstmount ]; then
    # Wait for MariaDB to be ready (with timeout)
    echo "Waiting for MariaDB..."
    timeout=210
    counter=0
    until mysqladmin ping --protocol=tcp --host=mariadb -u "$MYSQL_USER" --password="$MYSQL_PASSWORD" 2>/dev/null; do
        counter=$((counter+1))
        if [ $counter -gt $timeout ]; then
            echo "Timed out waiting for MariaDB."
            exit 1
        fi
        if [ $((counter % 5)) -eq 0 ]; then
            echo "Still waiting for MariaDB... ($counter/$timeout seconds)"
        fi
        sleep 1
    done
    echo "MariaDB is available!"

    # Check if WordPress is already installed
    if [ ! -f wp-config.php ]; then
        echo "Installing WordPress..."

        # Manual download and extraction
        if [ ! -f latest.tar.gz ]; then
            echo "Downloading WordPress..."
            curl -O https://wordpress.org/latest.tar.gz

            echo "Extracting WordPress..."
            tar -xzf latest.tar.gz --strip-components=1
            rm latest.tar.gz
        fi

        # Create wp-config.php
        if [ ! -f wp-config.php ]; then
            echo "Creating wp-config.php..."
            cp wp-config-sample.php wp-config.php

            # Update database settings
            sed -i "s/database_name_here/$MYSQL_DATABASE/g" wp-config.php
            sed -i "s/username_here/$MYSQL_USER/g" wp-config.php
            sed -i "s/password_here/$MYSQL_PASSWORD/g" wp-config.php
            sed -i "s/localhost/mariadb/g" wp-config.php

            # Add additional configuration
            sed -i "/That's all, stop editing/i define('FS_METHOD', 'direct');" wp-config.php

            # Generate unique keys and salts
            curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php
        fi

        # Use wp-cli for database setup
        echo "Setting up WordPress database..."
        wp core install --allow-root \
            --skip-email \
            --url="$DOMAIN_NAME" \
            --title="$WORDPRESS_TITLE" \
            --admin_user="$WORDPRESS_ADMIN_USER" \
            --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
            --admin_email="$WORDPRESS_ADMIN_EMAIL"

        # Create a regular user if specified
        if [ ! -z "$WORDPRESS_USER" ] && [ ! -z "$WORDPRESS_PASSWORD" ] && [ ! -z "$WORDPRESS_EMAIL" ]; then
            wp user create "$WORDPRESS_USER" "$WORDPRESS_EMAIL" --role=author --user_pass="$WORDPRESS_PASSWORD" --allow-root
        fi
    else
        echo "WordPress is already installed."
    fi

    # Set proper permissions
    chown -R nobody:nobody /var/www/html
    chmod -R 755 /var/www/html
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;

    touch .firstmount
fi

echo "Starting PHP-FPM..."
# This is the correct command for PHP 8.2 on Alpine
exec /usr/sbin/php-fpm82 -F
