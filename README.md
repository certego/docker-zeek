# README

Build:

```
sudo docker build -t certego/zeek:4.0.2 -f 4.0.2.Dockerfile .
```

Push

```
sudo docker push certego/zeek:4.0.2
```

# Managing GeoIP

To updatde geoip database add new files in geoip folder.

To build the image without geoip comment the line `ADD geoip/*.mmdb /usr/share/GeoIP/` in docker compose file and build with tag:
```
sudo docker build -t certego/zeek:3.0.12-nogeo -f 3.0.12.Dockerfile .
```

This product includes GeoLite2 data created by MaxMind, available from
<a href="https://www.maxmind.com">https://www.maxmind.com</a>.