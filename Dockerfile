FROM eniocarboni/docker-ubuntu-systemd:22.04

RUN apt update && apt install -y wget dirmngr git

COPY tgui_install tgui_install
ENV TZ=Europe/Moscow
RUN DEBIAN_FRONTEND="noninteractive" apt install -y tzdata
COPY config.php /root
RUN chmod 755 tgui_install/tacacsgui.sh && sudo tgui_install/tacacsgui.sh silent

