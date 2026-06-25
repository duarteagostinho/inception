#!/bin/bash


if [ ! -f /var/www/html/wp-config.php ]; then
	# downloads wordpress
	wp core download --path=/var/www/html --allow-root
	# creates a config file connected to the dbhost
	wp config create --path=/var/www/html --allow-root \
	--dbname=$MYSQL_DATABASE \
	--dbuser=$MYSQL_USER \
	--dbpass=$MYSQL_PASSWORD \
	--dbhost=mariadb
	# installs website
	wp core install --path=/var/www/html --allow-root \
	--url=https://$DOMAIN_NAME \
	--title=Inception \
	--admin_user=$WP_ADMIN_USER \
	--admin_password=$WP_ADMIN_PASSWORD \
	--admin_email=$WP_ADMIN_EMAIL
	# creates second user as required by subject
	wp user create --path=/var/www/html --allow-root \
	$WP_USER $WP_USER_EMAIL \
	--role=subscriber \
	--user_pass=$WP_USER_PASSWORD
fi

chown -R www-data:www-data /var/www/html

exec "$@"