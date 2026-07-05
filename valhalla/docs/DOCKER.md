# Docker Kullanımı

Proje resmi [valhalla-scripted](https://github.com/valhalla/valhalla/blob/master/docker/README.md) imajını kullanır.

## Temel komutlar

```bash
docker compose up -d
docker compose logs -f valhalla
docker compose restart valhalla
docker compose down
```

## Ortam değişkenleri

Container'a aktarılan değişkenler `.env` dosyasından okunur. Tam liste için `.env.example` ve resmi dokümantasyon.

## Nginx reverse proxy (opsiyonel)

Production'da TLS terminasyonu için:

```bash
docker compose --profile proxy up -d
```

Nginx yapılandırması: `valhalla/docker/nginx.conf`

## Özel imaj

```bash
docker build -f valhalla/docker/Dockerfile -t valhalla-stack:local .
```

`docker-compose.yml` içinde `image:` satırını değiştirin.

## Volume

`./valhalla/custom_files` → container `/custom_files`

Tüm tile, config ve PBF dosyaları bu dizinde kalır; container silinse bile veri korunur.
