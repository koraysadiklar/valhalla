# Tile Build (Build) Süreci

Valhalla scripted imajı ilk açılışta şu adımları otomatik yapar:

1. PBF indirme (`TILE_URLS`) veya `custom_files/*.osm.pbf` kullanımı
2. Admin veritabanı üretimi
3. Timezone veritabanı üretimi
4. Graph tile üretimi (`valhalla_build_tiles`)
5. Tile tarball oluşturma (`valhalla_tiles.tar`)
6. HTTP servis başlatma (`valhalla_service`)

## Süre tahminleri

| Bölge | PBF boyutu | Yaklaşık süre (4 thread) |
|-------|------------|--------------------------|
| Andorra | ~2 MB | 1-2 dk |
| İstanbul | ~15 MB | 5-10 dk |
| Türkiye | ~500 MB | 30-90 dk |
| Almanya | ~4 GB | birkaç saat |

## Zorla yeniden build

```bash
make rebuild
# veya
./valhalla/scripts/build.sh
```

## Tile dosyaları

Üretim sonrası `valhalla/custom_files/` içinde:

- `valhalla_tiles.tar` — routing graph
- `valhalla.json` — yapılandırma
- `admins.sqlite` — admin sınırları
- `timezones.sqlite` — saat dilimleri
- `.file_hashes.txt` — PBF hash takibi

## Temizlik

```bash
./valhalla/scripts/clean.sh
make rebuild
```
