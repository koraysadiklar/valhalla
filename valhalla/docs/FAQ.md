# Sık Sorulan Sorular

## Container bellekten öldürülüyor (OOM)

- `SERVER_THREADS=2` yapın
- Daha küçük bölge seçin (`istanbul.env`)
- `VALHALLA_MEMORY_LIMIT` artırın

## Servis açılmıyor, logda "No local PBF files"

- `.env` içinde `TILE_URLS` ayarlayın veya
- `./valhalla/scripts/download.sh` çalıştırın

## Tile build sonrası restart'ta tekrar build oluyor

- `USE_TILES_IGNORE_PBF=True` olduğundan emin olun
- `valhalla_tiles.tar` dosyasının `custom_files` içinde olduğunu kontrol edin

## Config değişikliği tile'ları yeniden üretir mi?

Hayır. `valhalla/custom_files/valhalla.json` düzenleyip `make restart` yeterli.

## Port değiştirme

`.env` → `VALHALLA_PORT=8003` → `make restart`

## Yedekleme

```bash
./valhalla/scripts/backup.sh
./valhalla/scripts/restore.sh valhalla/backups/valhalla_YYYYMMDD_HHMMSS.tar.gz
```

## Resmi kaynaklar

- [Valhalla GitHub](https://github.com/valhalla/valhalla)
- [Docker README](https://github.com/valhalla/valhalla/blob/master/docker/README.md)
- [API Dokümantasyonu](https://valhalla.github.io/valhalla/)
