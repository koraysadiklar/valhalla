.PHONY: install up down logs restart rebuild test status pull download backup clean update region proxy fix-docker

install:
	@./valhalla/scripts/bootstrap.sh
	@./valhalla/scripts/install.sh

up:
	@./valhalla/scripts/common.sh 2>/dev/null || true
	@bash -c 'source valhalla/scripts/common.sh && valhalla_start'

down:
	@docker stop valhalla 2>/dev/null || true
	@docker rm valhalla 2>/dev/null || true

logs:
	@docker logs -f valhalla

restart:
	@docker restart valhalla

rebuild:
	@./valhalla/scripts/build.sh

test:
	@./valhalla/scripts/test.sh

status:
	@./valhalla/scripts/health.sh

pull:
	@bash -c 'source valhalla/scripts/common.sh && valhalla_pull'

download:
	@./valhalla/scripts/download.sh

fix-pbf:
	@./valhalla/scripts/download.sh

backup:
	@./valhalla/scripts/backup.sh

clean:
	@./valhalla/scripts/clean.sh

update:
	@./valhalla/scripts/update.sh

proxy:
	@docker compose --profile proxy up -d 2>/dev/null || docker-compose --profile proxy up -d

region:
	@test -n "$(REGION)" || (echo "Kullanım: make region REGION=turkey" && exit 1)
	cp valhalla/regions/$(REGION).env .env
	@echo "Bölge ayarlandı: $(REGION).env -> .env"

fix-docker:
	@docker rm -f valhalla 2>/dev/null || true
	@docker-compose down --remove-orphans 2>/dev/null || docker compose down --remove-orphans 2>/dev/null || true
	@echo "Temizlendi. Tekrar: make install"
