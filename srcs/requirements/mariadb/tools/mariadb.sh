#!/bin/bash

set -e

db_password=$(cat /run/secrets/db_password | tr -d '\n\r')
root_password=$(cat /run/secrets/db_root_password | tr -d '\n\r')

mariadbd --user=mysql --skip-networking --socket=/run/mysqld/init.sock &
server_pid=$!

until mariadb-admin --socket=/run/mysqld/init.sock ping --silent; do
	sleep 1
done

root_password_args=()
if mariadb-admin --socket=/run/mysqld/init.sock -uroot -p"$root_password" ping --silent >/dev/null 2>&1; then
	root_password_args=(-p"$root_password")
fi

mariadb --socket=/run/mysqld/init.sock -uroot "${root_password_args[@]}" <<-EOF
	CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
	CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$db_password';
	ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$db_password';
	GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
	ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_password';
	FLUSH PRIVILEGES;
EOF

mariadb-admin --socket=/run/mysqld/init.sock -uroot -p"$root_password" shutdown
wait "$server_pid"

exec "$@"