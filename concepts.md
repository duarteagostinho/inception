# Inception: Core Concepts Study Guide

This guide explains the main ideas behind the Inception project. The goal is not
only to run the stack, but to understand why each part exists and how to debug it.

## How to use this guide

Do not try to memorize the whole project at once. Study it in this order:

1. Learn what a process, port, filesystem, and network are.
2. Learn the difference between an image, a container, and a volume.
3. Run a tiny Docker experiment before looking at the full stack.
4. Learn Compose and reproduce the same experiment with two services.
5. Learn each application service separately.
6. Trace one browser request through the complete infrastructure.
7. Practise breaking and repairing the stack.

For every new idea, ask three questions:

```text
What is it?
Why does this project need it?
What command or file lets me observe it?
```

The commands in this document are learning commands. Read them before running
them, and avoid commands containing `--rm`, `down -v`, or `prune` when you have
data you want to keep.

## 0. The computer ideas underneath Docker

Docker becomes much easier when four basic operating-system ideas are clear.

### 0.1 A process

A **process** is a running program. When you open a terminal and run:

```sh
echo hello
```

your shell starts an `echo` process. When MariaDB runs, `mariadbd` is a process.
When Nginx runs, `nginx` is a process.

The command:

```sh
ps aux
```

lists processes on your machine. Inside a container, it shows the processes
visible in that container.

Docker does not magically turn an application into a process. It starts an
ordinary Linux process with isolation around it.

### 0.2 A filesystem

A filesystem is the hierarchy of files and directories programs use:

```text
/etc       configuration
/var       changing application data
/run       runtime files such as sockets and PID files
/var/www   web application files
```

The path `/var/www/html` inside the WordPress and Nginx containers is not the
same path as `/var/www/html` on your laptop. Each container has its own view of
the filesystem, except where a volume is mounted.

### 0.3 A port

A port is a numbered communication endpoint belonging to a machine or network
namespace. A service listens on a port:

```text
Nginx      443
PHP-FPM    9000
MariaDB    3306
```

The number alone does not make a service reachable. Two things must be true:

1. A process must be listening.
2. The network path must allow the connection.

For example, MariaDB can listen on port 3306 inside Docker while remaining
unreachable from your laptop because Compose does not publish that port.

### 0.4 A hostname

A hostname is a name translated into an IP address. On the public side:

```text
duandrad.42.fr -> VM IP address
```

Inside the Compose network:

```text
wordpress -> WordPress container IP
mariadb   -> MariaDB container IP
```

Docker Compose provides the internal service-name lookup. You do not need to
discover container IP addresses manually, and you should not hard-code them.

## 0.5 What “localhost” means

`localhost` always means “this same network environment.”

There are several network environments in this project:

```text
your browser's machine
Nginx container
WordPress container
MariaDB container
```

Therefore:

```text
localhost from your browser  = your VM or laptop
localhost from WordPress     = WordPress container
localhost from MariaDB       = MariaDB container
```

If WordPress connects to `localhost:3306`, it looks for MariaDB inside the
WordPress container. That is wrong. It must connect to:

```text
mariadb:3306
```

## 0.6 A daemon and foreground mode

A **daemon** is a program that normally runs in the background and waits for
requests. Web servers and databases are commonly daemons.

Traditional Linux service managers start daemons for you. In a container, Docker
needs one main process to supervise. The service therefore runs in the
foreground:

```text
Nginx       nginx -g "daemon off;"
PHP-FPM     php-fpm8.2 -F
MariaDB     mariadbd --user=mysql
```

The foreground option does not change what the service does. It only keeps the
service attached to Docker's process lifecycle.

## 1. What the project builds

Inception is a small infrastructure made of three services:

```text
Browser
   |
   | HTTPS, TCP 443
   v
Nginx
   |
   | FastCGI, TCP 9000
   v
WordPress + PHP-FPM
   |
   | MySQL protocol, TCP 3306
   v
MariaDB
```

The services run in separate containers:

| Service | Responsibility | Publicly exposed? |
|---|---|---|
| Nginx | TLS termination and HTTP routing | Yes, port 443 |
| WordPress/PHP-FPM | Runs the WordPress PHP application | No |
| MariaDB | Stores the WordPress database | No |

Only Nginx is reachable from outside the Docker network. WordPress and MariaDB
communicate internally.

The subject requires this separation because each container should have one clear
responsibility.

## 2. Docker fundamentals

### 2.1 Image versus container

An **image** is a packaged filesystem and configuration. A **container** is a
running instance of an image.

Example:

```text
Dockerfile -> image -> container
```

The MariaDB Dockerfile describes how to build an image:

```dockerfile
FROM debian:bookworm-slim
RUN apt-get update -y && apt-get install -y mariadb-server
```

Compose then starts a container from that image:

```yaml
services:
  mariadb:
    build: ./requirements/mariadb
```

Images are generally replaceable. Important data must therefore be stored in
volumes rather than only in the container's writable layer.

### 2.2 Dockerfile instructions

Common instructions used in this project:

| Instruction | Meaning |
|---|---|
| `FROM` | Selects the base image |
| `RUN` | Executes a command while building the image |
| `COPY` | Copies project files into the image |
| `EXPOSE` | Documents the port used by the service |
| `ENTRYPOINT` | Defines the executable that always starts |
| `CMD` | Provides the default command or arguments |

`EXPOSE` does not publish a port to the host. Host exposure is configured in
Compose with `ports`.

### 2.3 PID 1 and foreground processes

The main process inside a container becomes PID 1. If it exits, the container
stops.

The services therefore run in the foreground:

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
CMD ["mariadbd", "--user=mysql"]
CMD ["/usr/sbin/php-fpm8.2", "-F"]
```

Running `nginx` as a background daemon would cause the container's main process to
finish immediately. Using `tail -f`, `sleep infinity`, or an infinite loop to keep
the container alive is a workaround, not a real service design.

Read more:

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker run reference](https://docs.docker.com/reference/cli/docker/container/run/)
- [Docker container lifecycle](https://docs.docker.com/engine/containers/run/)

### 2.4 Your first Docker experiment

Before studying the three-service project, run a container that does almost
nothing:

```sh
docker run --name hello-docker hello-world
```

Docker performs roughly these actions:

1. Looks for the `hello-world` image locally.
2. Downloads it if it is missing.
3. Creates a container from that image.
4. Starts the image's main process.
5. Shows the process output.
6. Stops the container when the process exits.

Inspect the stopped container:

```sh
docker ps
docker ps -a
docker inspect hello-docker
docker logs hello-docker
```

`docker ps` shows running containers. `docker ps -a` also shows stopped ones.
This distinction is important: a stopped container still exists and can still
have useful logs.

Remove the experiment:

```sh
docker rm hello-docker
```

Now run a long-lived web server:

```sh
docker run --name web-test -d -p 8080:80 nginx:1.26
```

Read this command from left to right:

| Part | Meaning |
|---|---|
| `docker run` | Create and start a container |
| `--name web-test` | Give it a readable name |
| `-d` | Detach and return the terminal |
| `-p 8080:80` | Host port 8080 forwards to container port 80 |
| `nginx:1.26` | Use the `nginx` image with the `1.26` tag |

Test it:

```sh
curl http://localhost:8080
docker logs web-test
docker exec -it web-test sh
```

`docker exec` starts another process inside an already-running container. It
does not replace the main process. Inside the shell, try:

```sh
hostname
ls /usr/share/nginx/html
ps
exit
```

Stop and remove it:

```sh
docker stop web-test
docker rm web-test
```

The important lesson is that `-p 8080:80` is directional:

```text
your machine:8080 -> container:80
```

It does not mean that every port inside the container is public.

### 2.5 Images are layered

Each Dockerfile instruction generally creates an image layer. Conceptually:

```text
Debian base layer
        +
installed packages
        +
configuration files
        +
startup script
        =
service image
```

If you change a later instruction, Docker can often reuse earlier layers from
cache. That is why this may be fast:

```sh
docker compose -f srcs/docker-compose.yml build
```

and this is deliberately slower:

```sh
docker compose -f srcs/docker-compose.yml build --no-cache
```

`--no-cache` is useful when you suspect an old package list or stale build layer,
but it is not a fix for every problem.

### 2.6 Tags are labels, not guarantees

An image reference has the form:

```text
name:tag
```

For example:

```text
debian:bookworm-slim
nginx:inception
```

The subject prohibits `latest` because it is a moving label. A build that works
today may change when `latest` points to a different release tomorrow. A named
tag is clearer and more reproducible, although digest pinning is even stricter.

### 2.7 Docker commands: create, start, stop, remove

These commands have different jobs:

```text
docker create  make a stopped container
docker start   start an existing container
docker stop    ask a running container to stop
docker rm      remove a stopped container
docker run     create and start a container
```

Compose has similar lifecycle commands:

```text
up       create and start services
stop     stop services but keep containers
start    start existing stopped containers
down     stop and remove containers and network
down -v  also remove named volumes
```

Understanding this prevents accidental data loss.

## 2.8 A first two-container network experiment

Create a small temporary Compose file outside the project:

```yaml
services:
  web:
    image: nginx:1.26
    ports:
      - "8080:80"
  client:
    image: busybox:1.36
    command: ["sh", "-c", "wget -qO- http://web || exit 1"]
```

Start it:

```sh
docker compose -f learning-compose.yml up
```

Compose puts both services on a private network and gives the first service the
DNS name `web`. The client does not use `localhost`; it uses:

```text
http://web
```

This is the same idea as:

```text
Nginx -> wordpress:9000
WordPress -> mariadb:3306
```

The temporary `client` exits after making its request. That is normal: a
container's lifetime is tied to its main process.

## 2.9 What Docker is not

Docker is not a full virtual machine:

| Virtual machine | Container |
|---|---|
| Runs a complete guest kernel | Shares the host kernel |
| Usually heavier | Usually lighter |
| Stronger machine-level separation | Process/filesystem/network isolation |
| Boots an operating system | Starts one or more application processes |

The subject still requires a virtual machine. Docker then runs inside that VM.
The VM provides the required Linux environment; containers provide service
isolation within it.

## 3. Docker Compose

The file `srcs/docker-compose.yml` describes the complete application:

```yaml
services:
  nginx:
  wordpress:
  mariadb:
```

Compose creates and connects:

- containers,
- a user-defined network,
- named volumes,
- secret mounts,
- service dependencies.

The Makefile is only a convenience interface. For example:

```make
all:
	docker compose -f srcs/docker-compose.yml up --build
```

The equivalent direct command is:

```sh
docker compose -f srcs/docker-compose.yml up --build
```

Useful commands:

```sh
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml down
```

Read more:

- [Docker Compose overview](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/reference/compose-file/)

## 4. Docker networking

The project defines a private bridge network:

```yaml
networks:
  inception:
    driver: bridge
```

Services attached to this network can find one another by service name.

For example, Nginx uses:

```nginx
fastcgi_pass wordpress:9000;
```

WordPress uses `mariadb` as its database host.

Do not use `localhost` for communication between containers. Inside the WordPress
container, `localhost` means the WordPress container itself, not MariaDB.

### 4.1 Published ports versus internal ports

Only Nginx has a `ports` entry:

```yaml
ports:
  - "443:443"
```

This means:

```text
host port 443 -> Nginx container port 443
```

MariaDB and PHP-FPM do not publish ports. They are reachable only over the
internal Docker network.

This is different from:

```yaml
network_mode: host
```

Host networking would remove much of the network isolation and is forbidden by the
subject.

Read more:

- [Docker networking overview](https://docs.docker.com/engine/network/)
- [Bridge networks](https://docs.docker.com/engine/network/drivers/bridge/)
- [Compose networking](https://docs.docker.com/compose/how-tos/networking/)

## 5. The request path through the stack

When a user visits:

```text
https://duandrad.42.fr/
```

the sequence is:

1. DNS or `/etc/hosts` maps `duandrad.42.fr` to the VM's IP address.
2. The browser connects to port 443.
3. Nginx performs the TLS handshake.
4. Nginx serves static files directly when possible.
5. Nginx forwards PHP requests to `wordpress:9000`.
6. PHP-FPM executes WordPress.
7. WordPress connects to MariaDB using the internal hostname `mariadb`.
8. MariaDB returns database results.
9. PHP-FPM returns generated HTML to Nginx.
10. Nginx returns the HTTPS response to the browser.

The Nginx PHP location is:

```nginx
location ~ \.php$ {
	fastcgi_pass wordpress:9000;
	fastcgi_index index.php;
	fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
	include fastcgi_params;
}
```

## 6. Nginx, PHP-FPM, and WordPress

These are separate responsibilities:

```text
Nginx       HTTP server and TLS endpoint
PHP-FPM     PHP process manager
WordPress   PHP application
```

Nginx does not execute PHP itself. It sends PHP requests using FastCGI to
PHP-FPM.

PHP-FPM listens on:

```ini
listen = 0.0.0.0:9000
```

Nginx connects to that port over the Docker network.

The subject requires WordPress/PHP-FPM without Nginx in the same container. This
keeps the service boundaries clear and allows each service to be restarted or
debugged independently.

### 6.1 Nginx for beginners

Nginx is both:

- an HTTP server, which receives browser requests;
- a reverse proxy, which forwards some requests to another service.

Its configuration is made of nested blocks:

```nginx
server {
    listen 443 ssl;
    server_name duandrad.42.fr;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }
}
```

Read it as:

```text
For HTTPS requests for this domain:
  if the requested file or directory exists, use it;
  otherwise send the request to WordPress's index.php.
```

The `location ~ \.php$` block uses a regular expression. It matches paths ending
in `.php`, such as:

```text
/index.php
/wp-login.php
```

The `fastcgi_param SCRIPT_FILENAME` line tells PHP-FPM which file to execute.
Without the correct filesystem path, Nginx may reach PHP-FPM but PHP-FPM will say
that the script does not exist.

Test the Nginx configuration inside the container:

```sh
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

### 6.2 PHP-FPM for beginners

PHP-FPM means **PHP FastCGI Process Manager**. It keeps PHP worker processes
available to execute PHP scripts.

It is not an HTTP server. You cannot normally open
`http://localhost:9000/` in a browser and expect an HTML page. Nginx speaks HTTP
to the browser and FastCGI to PHP-FPM.

The PHP-FPM configuration controls:

```ini
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
```

These values control how many PHP worker processes exist. More workers can
handle more simultaneous requests, but consume more memory.

The simplest request path is:

```text
Browser HTTP request
    -> Nginx
    -> FastCGI request
    -> PHP-FPM worker
    -> WordPress PHP code
    -> response to Nginx
```

### 6.3 MariaDB for beginners

MariaDB is a relational database server. It stores structured data in databases,
tables, rows, and columns.

Examples of WordPress data include:

```text
posts
users
comments
settings
```

A database server listens for client connections. WordPress is the client.
WordPress does not store every post as a separate PHP file; it asks MariaDB for
the data it needs.

Useful vocabulary:

| Term | Meaning |
|---|---|
| Server | The running MariaDB process |
| Database | A named collection of tables |
| Table | Structured data of one kind |
| User/account | Identity used to connect |
| Privilege | What an account is allowed to do |
| Host part | Where a database account may connect from |

This account:

```sql
'wordpress'@'%'
```

means the `wordpress` user may connect from hosts matching `%`. In this project,
the connection comes from the WordPress container, not from the MariaDB
container itself.

Connect interactively:

```sh
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb -u root -p
```

The terminal will ask for the root password. Once connected, try read-only
commands:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT ID, post_title FROM wp_posts LIMIT 5;
EXIT;
```

SQL commands usually end with `;`. The MariaDB prompt changes while it is waiting
for the end of a multi-line statement.

Read more:

- [MariaDB beginner tutorials](https://mariadb.com/kb/en/mariadb-tutorial/)
- [SQL SELECT](https://mariadb.com/kb/en/select/)
- [SQL GRANT](https://mariadb.com/kb/en/grant/)

### 6.4 WordPress for beginners

WordPress has two important parts here:

```text
WordPress files -> mounted in /var/www/html
WordPress data  -> stored in MariaDB
```

The files contain the application code, themes, plugins, and uploaded files.
The database contains content and configuration.

`wp-config.php` connects the two:

```text
database name
database user
database password
database host
```

The startup script generates this file with WP-CLI. It then runs the WordPress
installation and creates the second user.

WP-CLI is a command-line interface for WordPress. Examples:

```sh
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp core is-installed --path=/var/www/html --allow-root

docker compose -f srcs/docker-compose.yml exec wordpress \
  wp user list --path=/var/www/html --allow-root
```

The `--allow-root` option is needed because the initialization script runs as
root inside the container. The files are later assigned to `www-data`, the user
used by PHP-FPM.

Read more:

- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [FastCGI in Nginx](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)

## 7. TLS and HTTPS

Nginx is configured with:

```nginx
listen 443 ssl;
ssl_protocols TLSv1.2 TLSv1.3;
```

The certificate is self-signed for local development. Browsers will therefore
display a certificate warning.

The subject requires:

- Nginx as the only external entrypoint,
- host port 443 only,
- TLS 1.2 or TLS 1.3,
- no public MariaDB or PHP-FPM port.

Test the endpoint:

```sh
curl -k -I https://duandrad.42.fr/
```

The `-k` option tells `curl` to accept the self-signed certificate.

Inspect the certificate:

```sh
openssl s_client -connect duandrad.42.fr:443 \
	-servername duandrad.42.fr </dev/null
```

Read more:

- [NGINX HTTPS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [OpenSSL `s_client`](https://docs.openssl.org/master/man1/openssl-s_client/)

## 8. Volumes and persistence

Containers are disposable. Their writable filesystem layer should not be the only
place where important data exists.

This project uses two named volumes:

```yaml
volumes:
  - wp-data:/var/www/html
  - mariadb-data:/var/lib/mysql
```

They store different data:

```text
wp-data       WordPress files, uploads, plugins, themes, wp-config.php
mariadb-data  Database tables and MariaDB system data
```

The subject requires the named volumes to store their data under:

```text
/home/duandrad/data/wordpress
/home/duandrad/data/database
```

The Compose file uses the local volume driver to connect named Docker volumes to
those required VM paths.

### 8.1 Persistence commands

Stop containers but keep data:

```sh
docker compose -f srcs/docker-compose.yml down
```

Stop containers and delete the named volumes:

```sh
docker compose -f srcs/docker-compose.yml down -v
```

Inspect volumes:

```sh
docker volume ls
docker volume inspect srcs_wp-data
docker volume inspect srcs_mariadb-data
```

If `down` is followed by `up`, WordPress and its database should still exist.
After `down -v`, the stack should behave like a fresh installation.

Read more:

- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Compose volumes](https://docs.docker.com/reference/compose-file/volumes/)

## 9. Environment variables and secrets

Use environment variables for non-sensitive configuration:

```dotenv
DOMAIN_NAME=duandrad.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
WP_ADMIN_USER=siteowner
```

Passwords should not be placed in:

- Dockerfiles,
- tracked Compose files,
- Git commits,
- image build arguments,
- public documentation.

Compose secrets are mounted as files under:

```text
/run/secrets/db_password
/run/secrets/db_root_password
/run/secrets/wp_admin_password
/run/secrets/wp_user_password
```

The startup scripts read them with `cat`:

```sh
db_password=$(cat /run/secrets/db_password)
```

The repository's `.gitignore` excludes:

```text
/secrets/
/srcs/.env
```

The secret files still need to be created locally on the VM.

Read more:

- [Compose secrets](https://docs.docker.com/reference/compose-file/secrets/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [OWASP secrets management cheat sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

## 10. MariaDB initialization

MariaDB has two phases during startup.

### Phase 1: temporary initialization server

The script starts a temporary server on a Unix socket:

```sh
mariadbd --user=mysql \
	--skip-networking \
	--socket=/run/mysqld/init.sock &
```

This server is used to run setup SQL:

```sql
CREATE DATABASE IF NOT EXISTS `wordpress`;
CREATE USER IF NOT EXISTS 'wordpress'@'%';
GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpress'@'%';
```

`--skip-networking` ensures the temporary server is not exposed over TCP.

After setup:

```sh
mariadb-admin ... shutdown
```

### Phase 2: real MariaDB server

The temporary process exits and the Dockerfile command starts the actual server:

```dockerfile
CMD ["mariadbd", "--user=mysql"]
```

The normal server listens on port 3306 inside the Docker network.

The logs therefore normally show:

```text
temporary server starts
database setup occurs
temporary server shuts down
real server starts
ready for connections
```

The setup is designed to be **idempotent**. Running it again should not recreate
or damage the database. That is why it uses `IF NOT EXISTS`, `ALTER USER`, and
`GRANT`.

Read more:

- [MariaDB server system variables](https://mariadb.com/kb/en/server-system-variables/)
- [MariaDB account management](https://mariadb.com/kb/en/user-account-management/)

## 11. WordPress initialization

The WordPress startup script:

1. Reads secrets.
2. Downloads WordPress if its files are missing.
3. Creates `wp-config.php`.
4. Installs WordPress if the database is not installed.
5. Creates the second user if necessary.
6. Fixes file ownership.
7. Starts PHP-FPM.

Checking only for `wp-config.php` is not enough. A configuration file can exist even
if the previous database installation failed. The script therefore also checks:

```sh
wp core is-installed --path=/var/www/html --allow-root
```

The second user check is also idempotent:

```sh
wp user get "$WP_USER" ...
```

This prevents duplicate-user errors on container restarts.

## 12. Healthchecks and dependencies

Starting a container does not necessarily mean its service is ready. MariaDB may
still be initializing.

The Compose healthcheck runs:

```yaml
healthcheck:
  test: ["CMD-SHELL", "... mariadb-admin ping ..."]
```

WordPress waits for MariaDB to become healthy:

```yaml
depends_on:
  mariadb:
    condition: service_healthy
```

Nginx waits until the WordPress container has started:

```yaml
depends_on:
  wordpress:
    condition: service_started
```

Important distinction:

```text
service_started  container process has started
service_healthy  the healthcheck reports that the service is ready
```

Read more:

- [Compose startup order](https://docs.docker.com/compose/how-tos/startup-order/)
- [Docker healthchecks](https://docs.docker.com/reference/dockerfile/#healthcheck)

## 13. Restart behavior

Each service uses:

```yaml
restart: unless-stopped
```

This means Docker attempts to restart a service if its main process crashes, unless
the user explicitly stopped it.

Restart policy does not fix application errors. If a script exits immediately,
Docker may repeatedly restart the container. Always inspect logs:

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs --tail=100 mariadb
```

## 14. A repeatable debugging method

### 14.1 Learn to classify the failure

Do not begin by changing random files. First classify the failure:

| Symptom | First question |
|---|---|
| Image build fails | Which Dockerfile instruction failed? |
| Container is `Exited` | What did PID 1 print before exiting? |
| Container is `Restarting` | Is the startup command failing repeatedly? |
| Nginx returns `502` | Can Nginx resolve and reach PHP-FPM? |
| WordPress reports a database error | Is MariaDB healthy, and are credentials correct? |
| Site resets after recreation | Is the correct volume mounted? |
| Browser reports certificate trouble | Is this the expected self-signed certificate? |

The first error in the logs is usually more useful than the final error shown by
Compose. Compose often reports only that a dependent service failed.

### Step 1: Validate Compose

```sh
docker compose -f srcs/docker-compose.yml config
```

This catches YAML errors, missing secret files, bad interpolation, and invalid
Compose structure.

### Step 2: Build

```sh
docker compose -f srcs/docker-compose.yml build --no-cache
```

Read the first failing Dockerfile step. Later errors may only be consequences.

### Step 3: Check container state

```sh
docker compose -f srcs/docker-compose.yml ps
```

Interpret common states:

| State | Meaning |
|---|---|
| `Up` | Process is running |
| `Up (healthy)` | Process is running and healthcheck passes |
| `Restarting` | Main process is repeatedly crashing |
| `Exited` | Main process stopped |
| `Created` | Container exists but has not started |

### Step 4: Read targeted logs

```sh
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

Learn to read common messages:

```text
host not found in upstream "wordpress"
```

Nginx cannot resolve the service name. Check the Compose network and whether the
service exists.

```text
connect() failed (111: Connection refused)
```

The hostname may resolve, but nothing is accepting connections on that port.
Check whether PHP-FPM is running and listening.

```text
Access denied for user
```

MariaDB received a connection but rejected the account or password. Check the
secret files, the database user host, and whether an old volume contains old
credentials.

```text
Could not connect to database
```

The database may not be ready, the hostname may be wrong, or the network path may
be unavailable. Test each possibility separately.

### Step 5: Test network discovery

```sh
docker compose -f srcs/docker-compose.yml exec wordpress getent hosts mariadb
docker compose -f srcs/docker-compose.yml exec nginx getent hosts wordpress
```

### Step 6: Test the public endpoint

```sh
curl -k -I https://duandrad.42.fr/
```

### Step 7: Inspect processes

```sh
docker compose -f srcs/docker-compose.yml exec mariadb ps aux
docker compose -f srcs/docker-compose.yml exec wordpress ps aux
docker compose -f srcs/docker-compose.yml exec nginx ps aux
```

### Step 8: Check storage

```sh
docker volume ls
docker volume inspect srcs_wp-data
docker volume inspect srcs_mariadb-data
```

### 14.1.1 Debug from the inside out

When HTTPS fails, test each layer in order:

```text
1. Is the container running?
2. Is Nginx listening on 443?
3. Can the browser reach the host's 443?
4. Can Nginx resolve wordpress?
5. Is PHP-FPM listening on 9000?
6. Can WordPress resolve mariadb?
7. Is MariaDB healthy and accepting credentials?
8. Does WordPress have its files and database tables?
```

This is faster than changing Nginx, PHP, and MariaDB configuration at the same
time.

For example, a `502 Bad Gateway` from Nginx usually means the browser reached
Nginx successfully. The problem is farther along the path, often the
Nginx-to-PHP-FPM connection.

## 15. Beginner study roadmap

### Stage 1: Linux and processes

Learn:

- files and directories,
- users and permissions,
- processes,
- signals,
- TCP ports.

Practise:

```sh
ps aux
ls -l
id
ss -lnt
```

On macOS, `ss` may not exist; use:

```sh
lsof -nP -iTCP -sTCP:LISTEN
```

### Stage 2: Docker basics

Learn:

- images,
- containers,
- image tags,
- container lifecycle,
- published ports,
- logs,
- `exec`.

Practise the `hello-world` and Nginx experiments from section 2.

### Stage 3: Compose

Learn:

- services,
- networks,
- volumes,
- secrets,
- dependencies,
- healthchecks.

Practise the two-container network experiment before touching the project.

### Stage 4: The individual services

Study one service at a time:

1. Nginx: request routing and TLS.
2. PHP-FPM: FastCGI and worker processes.
3. MariaDB: users, databases, grants, and persistence.
4. WordPress: files, `wp-config.php`, WP-CLI, and database content.

### Stage 5: Full request tracing

Draw the request on paper:

```text
duandrad.42.fr
  -> VM IP
  -> port 443
  -> Nginx
  -> wordpress:9000
  -> MariaDB at mariadb:3306
  -> response
```

Then verify each arrow with a command or log.

### Stage 6: Failure exercises

Intentionally change one thing at a time:

- use `localhost` instead of `mariadb`;
- stop MariaDB;
- change the PHP-FPM port;
- remove the WordPress volume;
- use an incorrect database password;
- change the Nginx certificate path.

Predict the symptom, run the stack, read the logs, and restore the change.

## 16. Practical study exercises

Do these one at a time and predict the result before running the command.

### Exercise A: break and repair the network

Temporarily change:

```nginx
fastcgi_pass wordpress:9000;
```

to:

```nginx
fastcgi_pass localhost:9000;
```

Rebuild and observe the failure. Explain why `localhost` is wrong, then restore the
service hostname.

### Exercise B: observe persistence

1. Create a WordPress post.
2. Run `docker compose down`.
3. Run `docker compose up`.
4. Confirm the post still exists.
5. Run `docker compose down -v`.
6. Start again and observe the fresh installation.

### Exercise C: inspect the request path

Run:

```sh
curl -k -I https://duandrad.42.fr/
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
```

Identify which request reaches Nginx and which request reaches PHP-FPM.

### Exercise D: stop MariaDB

Run:

```sh
docker compose -f srcs/docker-compose.yml stop mariadb
docker compose -f srcs/docker-compose.yml ps
```

Observe the effect on WordPress and explain why a database-backed application cannot
serve normal requests without MariaDB.

## 17. Evaluation questions to practise

You should be able to answer these without reading the files:

1. Why is Nginx the only service with a published host port?
2. Why does Nginx use `wordpress:9000` rather than `localhost:9000`?
3. What happens to WordPress data when its container is deleted?
4. What does `docker compose down -v` remove?
5. Why are passwords mounted as files under `/run/secrets`?
6. Why does MariaDB have a temporary initialization phase?
7. Why does WordPress wait for MariaDB to be healthy?
8. What is the difference between an image and a container?
9. Why must the main service run in the foreground?
10. Why are Nginx, PHP-FPM, and MariaDB separate services?
11. Why is `/etc/hosts` needed for `duandrad.42.fr`?
12. What does TLS protect, and what does it not protect?
13. What is the difference between a Docker network and host networking?
14. Which data is persistent, and where is it stored?
15. What happens on the first WordPress startup versus a restart?

## 18. Final mental model

Remember these four layers:

```text
1. Build layer:
   Dockerfiles create service images.

2. Runtime layer:
   Compose starts one container per service.

3. Communication layer:
   The Docker network connects services by name.

4. Persistence/security layer:
   Volumes preserve data and secrets provide credentials.
```

If you understand those four layers, you can reason about most failures instead of
guessing:

- Build failure -> inspect the Dockerfile and package installation.
- Container restart -> inspect PID 1 and service logs.
- Connection failure -> inspect network names, ports, and readiness.
- Lost data -> inspect volume definitions and cleanup commands.
- Credential failure -> inspect secret files and initialization scripts.
- HTTPS failure -> inspect port 443, certificates, TLS settings, and Nginx logs.
