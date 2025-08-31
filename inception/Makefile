NAME = inception

# The shell command "pwd" gets the full path to current dir

SRC_PATH = $(shell pwd)

# The first taget (all) is the default traget when "make"

all : build up

# Build the custom images using docker-compose

build :
	docker-compose -f ./srcs/docker-compose.yml build

# Creat and start all containers in the background 

up :
	docker-compose -f ./srcs/docker-compose.yml up -d

# Stop and remove containers, network, but keeps the volumes

down :
	docker-compose -f ./srcs/docker-compose.yml down

# Stops containers and removes everything, including volumes and built images (a full reset)

clean : down
	docker-compose -f ./srcs/docker-compose.yml down -v --rmi all
	docker system prune -a --force

# Full clean rebuild: clean + build + up

re : clean all

# View logs from all services. Use "make logs s=nginx" to see only nginx logs

logs :
	docker-compose -f ./srcs/docker-compose.yml logs --follow $(s)

# Show the status of the containers (similar to "docker ps")

ps : 
	docker-compose -f ./srcs/docker-compose.yml ps

# Open a shell inside a running container. Usage: "make exec c=nginx"

exec :
	docker exec -it $(c) sh

# This target tells `make` that these rules are not actual files to be created

.PHONY : all build up down clean re logs ps exec

