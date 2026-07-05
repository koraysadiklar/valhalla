# Bölge Profilleri

`valhalla/regions/` altındaki `.env` dosyaları hazır yapılandırmalardır.

## Kullanım

```bash
cp valhalla/regions/turkey.env .env
make install
```

## Profiller

| Profil | PBF kaynağı | RAM |
|--------|-------------|-----|
| `istanbul.env` | Geofabrik İstanbul | 4G |
| `turkey.env` | Geofabrik Türkiye | 8G |
| `europe.env` | Geofabrik Almanya | 16G |
| `usa.env` | Geofabrik Kaliforniya | 8G |
| `australia.env` | Geofabrik Avustralya | 8G |
| `world.env` | Andorra (minimal test) | 2G |

## Özel bölge

[Geofabrik downloads](https://download.geofabrik.de/) adresinden PBF URL'si alın:

```env
TILE_URLS=https://download.geofabrik.de/europe/albania-latest.osm.pbf
```

Birden fazla PBF (bitişik bölgeler) boşlukla ayrılarak verilebilir; tek PBF önerilir.
