# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: user <user@student.42.fr>                  +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/01/01 00:00:00 by user              #+#    #+#              #
#    Updated: 2023/01/01 00:00:00 by user             ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception
DATA_DIR = ./data
COMPOSE_FILE = ./srcs/docker-compose.yml

# Check if docker compose is available, otherwise use docker-compose
DOCKER_COMPOSE = $(shell command -v docker-compose 2> /dev/null || echo "docker compose")

all: build up

build:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) build

up:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d

down:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down

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