FROM debian:bullseye-slim # slim is a stripped down, lighter version of a debian image

RUN apt-get update -y && \ 
	apt-get install -y mariadb-server

EXPOSE 3306

COPY ./tools/mariadb.sh /usr/local/bin

COPY ./conf/mariadb-server.conf /etc/mysql/mariadb.conf.d/50-server.cnf

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]

CMD ["mariadbd"]