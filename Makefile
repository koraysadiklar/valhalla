.PHONY: install up down logs restart rebuild test status pull download backup clean update region proxy

install:
	@./valhalla/scripts/install.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f valhalla

restart:
	docker compose restart valhalla

rebuild:
	@./valhalla/scripts/build.sh

test:
	@./valhalla/scripts/test.sh

status:
	@./valhalla/scripts/health.sh

pull:
	docker compose pull

download:
	@./valhalla/scripts/download.sh

backup:
	@./valhalla/scripts/backup.sh

clean:
	@./valhalla/scripts/clean.sh

update:
	@./valhalla/scripts/update.sh

proxy:
	docker compose --profile proxy up -d

region:
	@test -n "$(REGION)" || (echo "Kullanım: make region REGION=turkey" && exit 1)
	cp valhalla/regions/$(REGION).env .env
	@echo "Bölge ayarlandı: $(REGION).env -> .env"
