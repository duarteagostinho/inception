#!/bin/bash

set -e

db_password=$(cat /run/secrets/db_password)
admin_password=$(cat /run/secrets/wp_admin_password)
user_password=$(cat /run/secrets/wp_user_password)

if [ ! -f /var/www/html/wp-config.php ]; then
	wp core download --path=/var/www/html --allow-root --force
	wp config create --path=/var/www/html --allow-root \
	--dbname=$MYSQL_DATABASE \
	--dbuser=$MYSQL_USER \
	--dbpass="$db_password" \
	--dbhost=mariadb
fi

if ! wp core is-installed --path=/var/www/html --allow-root; then
	wp core install --path=/var/www/html --allow-root \
	--url=https://$DOMAIN_NAME \
	--title=Inception \
	--admin_user=$WP_ADMIN_USER \
	--admin_password="$admin_password" \
	--admin_email=$WP_ADMIN_EMAIL
fi

if ! wp user get "$WP_USER" --path=/var/www/html --allow-root >/dev/null 2>&1; then
	wp user create --path=/var/www/html --allow-root \
		"$WP_USER" "$WP_USER_EMAIL" \
		--role=subscriber \
		--user_pass="$user_password"
fi

chown -R www-data:www-data /var/www/html

exec "$@"