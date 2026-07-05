COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "docker compose"; fi)

.PHONY: install up down logs restart rebuild test status pull download backup clean update region proxy

install:
	@./valhalla/scripts/bootstrap.sh
	@./valhalla/scripts/install.sh

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f valhalla

restart:
	$(COMPOSE) restart valhalla

rebuild:
	@./valhalla/scripts/build.sh

test:
	@./valhalla/scripts/test.sh

status:
	@./valhalla/scripts/health.sh

pull:
	$(COMPOSE) pull

download:
	@./valhalla/scripts/download.sh

backup:
	@./valhalla/scripts/backup.sh

clean:
	@./valhalla/scripts/clean.sh

update:
	@./valhalla/scripts/update.sh

proxy:
	$(COMPOSE) --profile proxy up -d

region:
	@test -n "$(REGION)" || (echo "Kullanım: make region REGION=turkey" && exit 1)
	cp valhalla/regions/$(REGION).env .env
	@echo "Bölge ayarlandı: $(REGION).env -> .env"
