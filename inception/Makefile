NAME = inception
DATA_DIR = /home/alalauty/data
COMPOSE_FILE = ./srcs/docker-compose.yml

# Check if docker compose is available, otherwise use docker-compose
DOCKER_COMPOSE = docker compose

all: build up

build:
	@mkdir -p $(DATA_DIR)
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file ./srcs/.env build

up:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file ./srcs/.env up -d

down:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) --env-file ./srcs/.env down

clean: down
	@docker system prune -a --force

fclean: clean
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true

re: fclean all

ps:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) ps

logs:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs

.PHONY: all build up down clean fclean re ps logs