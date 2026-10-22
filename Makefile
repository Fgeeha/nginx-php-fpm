.DEFAULT_GOAL := help

.PHONY: help build test test-compat test-portal check

IMAGE ?= nginx-php-fpm:local
PLATFORM ?=
BUILDER ?= default

# Справка
help: ## Показать список целей
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# Сборка Docker
build: ## Собрать образ с обновлением базового образа
	docker buildx build --builder $(BUILDER) $(if $(PLATFORM),--platform $(PLATFORM)) --load --pull -t $(IMAGE) .

# Проверка
test: ## Проверить готовый образ и HTTP-запрос к PHP-FPM
	sh tests/smoke.sh $(IMAGE)
	OPcache=1 sh tests/smoke.sh $(IMAGE)

test-compat: ## Проверить прежние настройки и сценарии запуска
	sh tests/compat.sh $(IMAGE)

test-portal: ## Проверить внешний PHP-проект из APP_DIR без внешней сети
	sh tests/portal.sh $(IMAGE) "$(APP_DIR)"

check: build ## Собрать образ и выполнить проверки
	$(MAKE) test test-compat IMAGE=$(IMAGE)
