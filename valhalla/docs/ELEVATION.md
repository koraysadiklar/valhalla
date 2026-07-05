# Yükseklik (Elevation) Verisi

`.env` içinde `BUILD_ELEVATION=True` yapın ve container'ı yeniden başlatın.

Valhalla, routing graph kapsamındaki SRTM yükseklik karolarını otomatik indirir ve `valhalla/custom_files/elevation_data/` altına kaydeder.

## Manuel elevation karoları

HGT formatında dosyalar şu yapıda olmalı:

```
valhalla/custom_files/elevation_data/
  N41/
    N41E028.hgt
    N41E029.hgt
```

Format: [Skadi HGT](https://github.com/tilezen/joerd/blob/master/docs/formats.md#skadi)

## `/height` servisi

```bash
curl http://localhost:8002/height \
  -H "Content-Type: application/json" \
  -d @valhalla/examples/height.json
```

Mevcut graph üzerinde yeni elevation verisi kullanmak için graph rebuild gerekmez; container restart yeterli.

Graph tile'larına elevation eklemek için `BUILD_ELEVATION=True` ile rebuild gerekir.
