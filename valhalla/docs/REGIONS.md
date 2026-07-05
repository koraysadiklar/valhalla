# Valhalla Bölge Profilleri

## Hızlı komutlar

```bash
make regions                          # Tüm profilleri listele
make region REGION=europe && make install   # Tüm Avrupa
make region REGION=turkey && make install   # Türkiye
make region REGION=world && make install    # Planet (64 GB+ RAM)
```

---

## Kıtalar

| Komut | PBF | Tile (tahmini) | Build süresi | Min RAM | Min disk |
|-------|-----|----------------|--------------|---------|----------|
| `REGION=europe` | ~32 GB | ~150 GB | 24-72 saat | 16 GB | 200 GB |
| `REGION=asia` | ~14 GB | ~80 GB | 12-48 saat | 16 GB | 120 GB |
| `REGION=north-america` | ~16 GB | ~90 GB | 18-48 saat | 16 GB | 130 GB |
| `REGION=africa` | ~6 GB | ~40 GB | 6-24 saat | 16 GB | 60 GB |
| `REGION=south-america` | ~3 GB | ~20 GB | 4-12 saat | 16 GB | 30 GB |
| `REGION=oceania` | ~1.5 GB | ~12 GB | 2-8 saat | 16 GB | 20 GB |

## Dünya (Planet)

| Komut | PBF | Tile | Build | Min RAM | Min disk |
|-------|-----|------|-------|---------|----------|
| `REGION=world` | ~80 GB | ~400+ GB | 3-7 gün | **64 GB** | **600 GB** |

> 16 GB RAM ile planet build büyük ihtimalle başarısız olur. Sunucuyu büyüttükten sonra deneyin.

## Ülkeler / test

| Komut | Açıklama |
|-------|----------|
| `REGION=turkey` | Türkiye (~607 MB) |
| `REGION=germany` | Almanya (~4 GB) |
| `REGION=test` | Andorra (~2 MB, hızlı test) |

---

## 750 GB Volume kullanımı

Tüm kıta profilleri veriyi volume'a yazar:

```env
VALHALLA_DATA_DIR=/mnt/volume_ams3_1782933520272/valhalla-data/europe
```

Sunucunuzda volume yolunu kontrol edin:

```bash
df -h /mnt/volume_ams3_1782933520272
```

Profil seçmeden önce `.env` içindeki `VALHALLA_DATA_DIR` yolunu düzenleyin.

---

## Sizin sunucu (4 CPU, 16 GB RAM, 750 GB volume)

| Profil | Uygun mu? |
|--------|-----------|
| **europe** | Evet — sıkı ama mümkün (`SERVER_THREADS=2`) |
| asia, north-america | Evet — benzer |
| africa, south-america, oceania | Rahat |
| **world (planet)** | Hayır — RAM 64 GB+ gerekir |

---

## Avrupa kurulumu

```bash
git pull
make region REGION=europe
make install
```

`make install` otomatik olarak:
1. `/mnt/volume_.../valhalla-data/europe/` altına PBF indirir (~32 GB)
2. Tile build başlatır (24-72 saat)
3. İlerlemeyi aşama aşama gösterir

Arka plada izlemek için ayrı terminal:

```bash
make logs
```

---

## Sunucu büyütme sonrası (planet için)

`.env` veya `world.env` içinde:

```env
SERVER_THREADS=4
VALHALLA_MEMORY_LIMIT=60g
INSTALL_WAIT_HOURS=168
VALHALLA_DATA_DIR=/mnt/volume_ams3_1782933520272/valhalla-data/world
TILE_URLS=https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
```

```bash
make region REGION=world
make install
```
