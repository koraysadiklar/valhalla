# Valhalla Stack

OpenStreetMap tabanlı [Valhalla](https://github.com/valhalla/valhalla) routing motorunu sunucuya tek komutla kurmak için hazırlanmış deployment projesi.

Resmi `ghcr.io/valhalla/valhalla-scripted` Docker imajı kullanılır.

## Hızlı başlangıç

```bash
chmod +x valhalla/scripts/*.sh

make region REGION=turkey
make install
```

`make install` otomatik olarak:
1. Bağımlılıkları kurar (`make`, `wget`, `curl`)
2. Eski PBF'yi siler, yeniden indirir
3. Container'ı başlatır ve build'i izler

## Gereksinimler (sunucunuza göre)

| Profil | PBF | Disk | RAM | Build süresi |
|--------|-----|------|-----|--------------|
| `test` | 2 MB | 1 GB | 2 GB | 2 dk |
| `turkey` | 600 MB | 20 GB | 8 GB | 1 saat |
| `europe` | 32 GB | 200 GB | 16 GB | 24-72 saat |
| `world` | 80 GB | 600 GB | **64 GB** | 3-7 gün |

```bash
make regions              # Tüm profilleri listele
make region REGION=europe # Kıta/ülke seç
make install              # Kur
```

Detay: [valhalla/docs/REGIONS.md](valhalla/docs/REGIONS.md)

## Komutlar

| Komut | Açıklama |
|-------|----------|
| `make install` | Tam kurulum (env + pull + up + bekle) |
| `make regions` | Tüm bölge profillerini listele |
| `make region REGION=europe` | Kıta/ülke profili seç |
| `make download` | PBF indir |
| `make up` / `make down` | Başlat / durdur |
| `make logs` | Logları izle |
| `make rebuild` | Tile'ları yeniden üret |
| `make test` | API testleri |
| `make backup` | custom_files yedekle |
| `make proxy` | Nginx reverse proxy (port 80) |

## API

```bash
curl http://localhost:8002/status

curl http://localhost:8002/route \
  -H "Content-Type: application/json" \
  -d @valhalla/examples/route.json
```

## Proje yapısı

```
valhalla-stack/
├── docker-compose.yml
├── .env.example
├── Makefile
├── valhalla/
│   ├── custom_files/     # Docker volume (PBF, tile, config)
│   ├── data/pbf/         # PBF indirme alanı
│   ├── regions/          # Hazır bölge profilleri
│   ├── scripts/          # Kurulum ve bakım scriptleri
│   ├── examples/         # API istek örnekleri
│   ├── config/           # valhalla.json şablonu
│   ├── docker/           # Nginx + opsiyonel Dockerfile
│   ├── docs/             # Detaylı dokümantasyon
│   └── tests/            # API test scriptleri
```

## Dokümantasyon

- [Kurulum](valhalla/docs/INSTALL.md)
- [API örnekleri](valhalla/docs/API.md)
- [Tile build süreci](valhalla/docs/BUILD.md)
- [Docker](valhalla/docs/DOCKER.md)
- [Bölgeler](valhalla/docs/REGIONS.md)
- [SSS](valhalla/docs/FAQ.md)

## Lisans

MIT — Valhalla [MIT](https://github.com/valhalla/valhalla/blob/master/COPYING), OSM verisi [ODbL](https://www.openstreetmap.org/copyright).
