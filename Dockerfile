FROM eniocarboni/docker-ubuntu-systemd:22.04

# set repos
#RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 40976EAF437D05B5 && \
#    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3B4FE6ACC0B21F32
#RUN echo "" > /etc/apt/sources.list && echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial universe\n\
#    deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates universe\n\
#    deb http://us.archive.ubuntu.com/ubuntu/ xenial main restricted\n\
#    deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates main restricted\n"\
#    >> /etc/apt/sources.list

#RUN apt-get update && apt-get upgrade -y && apt-get install -y python3-mysqldb libmysqlclient-dev python3-dev\
#  make gcc openssl apache2 lwresd \
#  curl zip unzip libnet-ldap-perl ldap-utils ntp \
#  libapache2-mod-xsendfile libpcre3-dev:amd64 libbind-dev

# install php composer
#RUN curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php && \
#    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

#RUN apt-get install -y php7.3 php7.3-common php7.3-cli php7.3-fpm php7.3-curl php7.3-dev php7.3-gd php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml libapache2-mod-php7.3 php7.3-ldap
#RUN a2dismod php7.* && sudo a2enmod php7.3 && service apache2 restart
RUN apt update && apt install -y wget dirmngr git

COPY tgui_install tgui_install
ENV TZ=Europe/Moscow
RUN DEBIAN_FRONTEND="noninteractive" apt install -y tzdata
COPY config.php /root
RUN chmod 755 tgui_install/tacacsgui.sh && sudo tgui_install/tacacsgui.sh silent

