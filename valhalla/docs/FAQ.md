# Sık Sorulan Sorular

## Admin build: RTTOPO / degenerate uyarıları (Avrupa vb.)

Logda şunları görüyorsanız **endişelenmeyin**, build devam eder:

```
RTTOPO warning: Self-intersection at or near point ...
[WARN] España ... is degenerate and will be skipped
[WARN] Nederland ... is missing way member ... will be skipped
```

**Neden olur?**
- OpenStreetMap admin sınırları her zaman mükemmel değildir
- Sınır bölgeleri (Rusya, Suriye, Kafkasya, Ceuta vb.) sık atlanır
- Valhalla bozuk polygon'ları atlayıp geri kalanıyla devam eder

**Routing etkilenir mi?**
- Genel rota hesaplama **çalışır**
- Bazı sınır geçişi / driving side metadata'ları o bölgelerde eksik olabilir
- Pratikte Avrupa genelinde rota kalitesi yeterlidir

**Durdurma / düzeltme gerekir mi?** Hayır. `make logs` ile izlemeye devam edin.

---

## `sqlite3_step() error: NOT NULL constraint failed: admin_access.admin_id`

Admin DB bittikten sonra görülebilir:

```
[ERROR] sqlite3_step() error: NOT NULL constraint failed: admin_access.admin_id.
Ignore if not using a planet extract or check if there was a name change for Spain
```

**Avrupa (veya kıta) extract kullanıyorsanız bu normaldir.** Valhalla'nın kendi mesajı: *"Ignore if not using a planet extract"*.

- `admin_access` tablosu dünya genelindeki ülkeleri referans alır
- Europe PBF'de ABD, Brezilya, Çin vb. yok → admin_id NULL → hata loglanır, build **devam eder**
- İspanya, Hollanda, Norveç gibi Avrupa ülkeleri de OSM'de bozuk sınır nedeniyle atlandıysa aynı mesaj çıkabilir

`Finished.` ve ardından `Building timezone db` görüyorsanız admin aşaması **başarılı** demektir.

---

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
