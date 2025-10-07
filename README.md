# Tacacsgui docker

Hi there! This is my dockerfile for [tacacsgui](https://github.com/tacacsgui/tacacsgui), so you can run it anywhere, not only ubuntu:20.04 as in default installation script [tgui_install](https://github.com/tacacsgui/tgui_install).

Check [docker image](https://hub.docker.com/r/karpov780/tacgui) builded from this repo.

I use ubuntu22.04 with systemctl as base image and run modified script from [tgui_install](https://github.com/tacacsgui/tgui_install). You can check it in ```tgui_install```.
It doesn`t install MySQL and set database, instead of this you can use your own MySQL instance. Check ```docker-compose.yaml```

## Set the credentials

Set passwords for databse user tgui_user:
1. In file init-db.sql change ```some_password``` (string 4) to strong password, that tgui_user will use.
2. In file config.php change ```some_password``` (string 11) to same password.

## Run docker-compose

``` bash
docker compose up -d
```

## Build and run image:

``` bash
docker build . -t tacgui:latest
docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro --volume=./config.php:/opt/tacacsgui/web/api/config.php tacgui:latest
```

# After start

Check:
https://your_ip:4443
http://your_ip:8008
