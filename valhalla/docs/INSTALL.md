# Valhalla Stack — Kurulum

## Tek komut

```bash
chmod +x valhalla/scripts/*.sh valhalla/tests/*.sh
make install
```

## Adım adım

```bash
cp .env.example .env
# veya bölge seçin:
cp valhalla/regions/turkey.env .env

make pull
make up
make logs
```

## Bölge değiştirme

`valhalla/regions/` altındaki hazır profillerden birini `.env` olarak kopyalayın:

| Dosya | Açıklama |
|-------|----------|
| `istanbul.env` | Hızlı test (~15MB) |
| `turkey.env` | Türkiye tam harita |
| `europe.env` | Almanya örneği |
| `world.env` | Andorra minimal test |

Değişiklikten sonra:

```bash
make download-pbf   # veya container TILE_URLS ile indirir
make rebuild
```

## Gereksinimler

- Docker 24+ ve Compose v2
- 8 GB+ RAM (Türkiye için)
- 20 GB+ disk

Detaylı bilgi: [README.md](../../README.md)
