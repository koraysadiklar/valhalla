.PHONY: install up down logs restart rebuild test status download backup clean region regions

install:
	@./valhalla/scripts/bootstrap.sh
	@./valhalla/scripts/install.sh

up:
	@bash -c 'source valhalla/scripts/common.sh && valhalla_start'

down:
	@bash -c 'source valhalla/scripts/common.sh && valhalla_cleanup_containers'

logs:
	@bash -c 'source valhalla/scripts/common.sh; id=$$(valhalla_container_id); docker logs -f $${id:-valhalla}'

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

volume-check:
	@sudo ./valhalla/scripts/setup-volume.sh

swap:
	@sudo ./valhalla/scripts/setup-swap.sh

resize-volume:
	@sudo resize2fs /dev/sda && df -h /mnt/volume_ams3_1782933520272

regions:
	@echo "Kullanım: make region REGION=<isim>"
	@echo ""
	@echo "  Kıtalar:"
	@echo "    europe          Tüm Avrupa (~32 GB PBF, 72 saat build)"
	@echo "    asia            Tüm Asya (~14 GB)"
	@echo "    africa          Tüm Afrika (~6 GB)"
	@echo "    north-america   Kuzey Amerika (~16 GB)"
	@echo "    south-america   Güney Amerika (~3 GB)"
	@echo "    oceania         Avustralya + Okyanusya (~1.5 GB)"
	@echo ""
	@echo "  Dünya:"
	@echo "    world           Planet + elevation (~80 GB PBF, 32GB RAM+swap)"
	@echo ""
	@echo "  Ülkeler / test:"
	@echo "    turkey          Türkiye"
	@echo "    germany         Almanya"
	@echo "    test            Andorra (hızlı test)"
	@echo ""
	@echo "Örnek: make region REGION=europe && make install"

region:
	@test -n "$(REGION)" || ($(MAKE) regions && exit 1)
	@cp valhalla/regions/$(REGION).env .env
	@echo "Bölge: $(REGION) → .env"
	@grep -E '^TILE_URLS=|^VALHALLA_DATA_DIR=|^SERVER_THREADS=' .env || true
