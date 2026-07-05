.PHONY: install up down logs restart rebuild test status download backup clean region

install:
	@./valhalla/scripts/bootstrap.sh
	@./valhalla/scripts/install.sh

up:
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

download:
	@./valhalla/scripts/download.sh

backup:
	@./valhalla/scripts/backup.sh

clean:
	@./valhalla/scripts/clean.sh

region:
	@test -n "$(REGION)" || (echo "Kullanım: make region REGION=turkey" && exit 1)
	@cp valhalla/regions/$(REGION).env .env
	@echo "Bölge: $(REGION) → .env"
