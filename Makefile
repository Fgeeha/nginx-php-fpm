.DEFAULT_GOAL := help

.PHONY: help build test check

IMAGE ?= nginx-php-fpm:local

# Справка
help: ## Показать список целей
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# Сборка Docker
build: ## Собрать образ с обновлением базового образа
	docker build --pull -t $(IMAGE) .

# Проверка
test: ## Проверить готовый образ и HTTP-запрос к PHP-FPM
	sh tests/smoke.sh $(IMAGE)
	OPcache=1 sh tests/smoke.sh $(IMAGE)

check: build ## Собрать образ и выполнить проверки
	$(MAKE) test IMAGE=$(IMAGE)
