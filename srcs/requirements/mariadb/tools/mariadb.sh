#!/bin/bash

set -e

chown -R mysql:mysql /var/lib/mysql

db_password=$(cat /run/secrets/db_password | tr -d '\n\r')
root_password=$(cat /run/secrets/db_root_password | tr -d '\n\r')

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

cat > /run/mysqld/init.sql <<-EOF
	DROP DATABASE IF EXISTS test;
	DELETE FROM mysql.user WHERE User='';
	CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
	CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$db_password';
	ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$db_password';
	GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
	ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_password';
	FLUSH PRIVILEGES;
EOF
chown mysql:mysql /run/mysqld/init.sql
chmod 600 /run/mysqld/init.sql

exec "$@" --init-file=/run/mysqld/init.sql
