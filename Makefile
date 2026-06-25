all:
	docker-compose -f srcs/docker-compose.yaml up --build

down:
	docker-compose -f srcs/docker-compose.yaml down

clean:
	docker-compose -f srcs/docker-compose.yaml down -v

fclean: clean
	docker system prune -a -f

re: fclean all
