# Valhalla API Örnekleri

Servis varsayılan olarak `http://localhost:8002` adresinde çalışır.

## Durum

```bash
curl http://localhost:8002/status
```

## Rota

```bash
curl http://localhost:8002/route \
  -H "Content-Type: application/json" \
  -d @valhalla/examples/route.json
```

## Isochrone

```bash
curl http://localhost:8002/isochrone \
  -H "Content-Type: application/json" \
  -d '{
    "locations": [{"lat": 41.0082, "lon": 28.9784}],
    "costing": "auto",
    "contours": [{"time": 15, "color": "ff0000"}]
  }'
```

## Mesafe matrisi

```bash
curl http://localhost:8002/sources_to_targets \
  -H "Content-Type: application/json" \
  -d '{
    "sources": [{"lat": 41.0082, "lon": 28.9784}],
    "targets": [{"lat": 41.0151, "lon": 29.0094}],
    "costing": "auto"
  }'
```

## Map matching

```bash
curl http://localhost:8002/trace_route \
  -H "Content-Type: application/json" \
  -d @valhalla/examples/trace.json
```

## Yükseklik

```bash
curl http://localhost:8002/height \
  -H "Content-Type: application/json" \
  -d @valhalla/examples/height.json
```

Resmi referans: [Valhalla API](https://valhalla.github.io/valhalla/api/turn-by-turn/api-reference/)
