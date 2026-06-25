#!/bin/bash

# if there is no volume, create one
if [ ! -d "/var/lib/mysql/mysql" ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql

# the variables used here are expanded to the values stored in .env
mariadbd --user=mysql --datadir=/var/lib/mysql --bootstrap <<-EOF # bootstrap allows us to create default values in the db in a single execution
	CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE; 
	CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
	GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
	ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
	FLUSH PRIVILEGES;
	EOF
fi
exec "$@"