#!/bin/bash
# TacacsGUI Install Script
# Author: Aleksey Mochalin
clear;
####  VARIABLES  ####
#ROOT_PATH="/opt/tacacsgui"
####  FUNCTIONS ####
if [[ ! -z $1 ]]; then
	MAIN_PATH=$1
else
	MAIN_PATH=$PWD
fi

source "$MAIN_PATH/inc/src/map.sh";
echo $FUN_GENERAL
# echo $MAIN_PATH
source "$FUN_GENERAL";
source "$FUN_IFACE";
source "$FUN_INSTALL";
#if [ $# -eq 0 ]; then
	SCRIPT_VER="2.0.0";
	echo $'\n'\
"###############################################################"$'\n'\
"##############   TACACSGUI Installation    #########"$'\n'\
"###############################################################"$'\n'$'\n'"ver. ${SCRIPT_VER}"$'\n'$'\n'\

	echo 'Start Installation';
	SILENT='0'
	if [[ ! -z $2 ]] && [[ $2 == 'silent' ]]; then
		echo 'Silent installation detected!'
		SILENT='1'
	fi

	###Creating main directory###
	echo -n "Check main directory /opt/tacacsgui ";

	if [ ! -d /opt/tacacsgui/ ]; then
		echo "... Creating directory";
		mkdir /opt/tacacsgui
	else
		echo "... Already Created";
	fi
	chown www-data:www-data -R /opt/tacacsgui
	if [ $(ls -la /opt/tacacsgui/ | wc -l) -gt 3 ]; then
		if [[ SILENT == '0' ]]; then
			echo -n "Directory /opt/tacacsgui doesn't empty. Delete all files? (if no, script exit) [y/n]: "; read DECISION;
			if [ "$DECISION" == "${DECISION#[Yy]}" ]; then
				read -n 1 -s -r -p "Press any key to exit...";
				exit 0;
			fi
		fi
		if [ -f '/opt/tacacsgui/tac_plus.cfg' ]; then
			cp /opt/tacacsgui/tac_plus.cfg /tmp/tac_plus.cfg
			echo "Old configuration saved! (tac_plus.cfg)";
		fi
		rm -R /opt/tacacsgui/* --force
		rm -Rf /opt/tacacsgui/.* 2> /dev/null
	fi
	echo "Download latest version..."
	sudo -u  www-data git -C /opt/tacacsgui clone https://github.com/tacacsgui/tacacsgui /opt/tacacsgui
	chmod 774 /opt/tacacsgui/main.sh /opt/tacacsgui/backup.sh /opt/tacacsgui/tac_plus.sh
	chmod 777 /opt/tacacsgui/parser/tacacs_parser.sh
	sudo -u  www-data touch /opt/tacacsgui/tacTestOutput.txt
	sudo -u  www-data touch /opt/tacacsgui/tac_plus.cfg
	sudo -u  www-data touch /opt/tacacsgui/tac_plus.cfg_test
	sudo -u  www-data chmod 666 /opt/tacacsgui/tac_plus.cfg*
	sudo -u  www-data chmod 666 /opt/tacacsgui/tacTestOutput.txt
	sudo -u  www-data composer update -d /opt/tacacsgui/web/api
	sudo -u  www-data composer install -d /opt/tacacsgui/web/api
	echo "Download python libraries..."
	umask 022
	sudo pip install sqlalchemy alembic mysqlclient pexpect pyyaml argparse pyotp gitpython
	echo "Update python libraries..."
	python3 -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | while read line; do \
			if [[ $line == 'pycurl' ]] || [[ $line == 'pygobject' ]]; then
				continue
			fi
			sudo pip install --upgrade "${line}"; \
		done
	echo "Time to create certificate for https support...";
	if [ ! -d "/opt/tgui_data/ssl" ]; then
		mkdir -p /opt/tgui_data/ssl
	fi
	if [ ! -f '/opt/tgui_data/ssl/tacacsgui.local.cer' ] || [ ! -f '/opt/tgui_data/ssl/tacacsgui.local.key' ]; then
		sudo openssl req -subj '/CN=domain.com/O=My./C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /opt/tgui_data/ssl/tacacsgui.local.key -out /opt/tgui_data/ssl/tacacsgui.local.cer
		echo -n "Done."
	else
		echo -n "Already created."
	fi
        ###GENERATE CONFIGURATION FILE###
	cp /root/config.php /opt/tacacsgui/web/api/config.php	
	###PREPARING APACHE2###
	echo "Preparing apache configuration";

	if [ ! -d /var/log/tacacsgui/apache2/ ]; then
		mkdir -p /var/log/tacacsgui/apache2
	fi
	service apache2 start
	cp $APACHE_FILES_DIR/tacacsgui.local* /etc/apache2/sites-available/
	sudo a2enmod rewrite
	service apache2 reload
	sudo a2enmod ssl
	sudo service apache2 reload
	sudo a2enmod xsendfile
	sudo service apache2 reload
	a2ensite tacacsgui.local.conf
	service apache2 reload
	a2ensite tacacsgui.local-ssl.conf
	service apache2 reload
###TAC_PLUS DAEMON SETUP###
	echo "Tacacs Daemon setup..."
	if [[ ! -f /etc/init/tac_plus.conf ]]; then
		touch /etc/init/tac_plus.conf
		echo '#tac_plus daemon
		description "tac_plus daemon"
		author "Marc Huber"
		start on runlevel [2345]
		stop on runlevel [!2345]
		respawn
		# Specify working directory
		chdir /opt/tacacsgui
		exec tac_plus.sh' > /etc/init/tac_plus.conf;
		cp /opt/tacacsgui/tac_plus.sh /etc/init.d/tac_plus
		sudo systemctl enable tac_plus
		echo "Daemon apploaded";
	fi
	echo -n "Test Daemon work...";
	if [ -f '/tmp/tac_plus.cfg' ]; then
		cp /tmp/tac_plus.cfg /opt/tacacsgui/tac_plus.cfg;
		echo "Old configuration repaired";
	elif [[ $(service tac_plus status 2>/dev/null | grep "active (running)" | wc -l) -eq 0 ]]; then
		cat $TACACS_CONF_TEST > /opt/tacacsgui/tac_plus.cfg
		service tac_plus start
		sleep 5
                echo "Status";
		service tac_plus status;
	else
		echo -n "Already running..."
	fi
	echo "Done";
###tgui_data###
	if [ ! -d "/opt/tgui_data/backups" ]; then
		mkdir -p /opt/tgui_data/backups
	fi
	if [ ! -d "/opt/tgui_data/ha" ]; then
		mkdir -p /opt/tgui_data/ha
	fi
	if [ ! -f /opt/tgui_data/ha/ha.yaml ]; then
		touch /opt/tgui_data/ha/ha.yaml
		echo -n '[]' > /opt/tgui_data/ha/ha.yaml
	fi
	if [ ! -d "/opt/tgui_data/confManager/configs" ]; then
		mkdir -p /opt/tgui_data/confManager/configs
	fi
	if [ ! -f /opt/tgui_data/confManager/config.yaml ]; then
		touch /opt/tgui_data/confManager/config.yaml
		echo -n '[]' > /opt/tgui_data/confManager/config.yaml
	fi
	if [ ! -f /opt/tgui_data/confManager/cron.yaml ]; then
		touch /opt/tgui_data/confManager/cron.yaml
		echo -n '[]' > /opt/tgui_data/confManager/cron.yaml
	fi
	chown www-data:www-data -R /opt/tgui_data
###FINAL CHECK###
	echo -n 'Final Check...';
	echo -n 'Check main libraries...'

	if [ ! -d /opt/tacacsgui/web/api/vendor/slim/ ]; then
		echo;
		error_message "Slim Framework not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [ ! -d /opt/tacacsgui/web/api/vendor/slim/ ]; then
		echo;
		error_message "Slim Framework not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [ ! -d /opt/tacacsgui/web/api/vendor/illuminate/ ]; then
		echo;
		error_message "Illuminate Database not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [ ! -d /opt/tacacsgui/web/api/vendor/respect/ ]; then
		echo;
		error_message "Respect Validation not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [ ! -d /opt/tacacsgui/web/api/vendor/respect/ ]; then
		echo;
		error_message "Respect Validation not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	python_libs="$(pip list --format=freeze 2>/dev/null | grep -v '^\-e' | cut -d = -f 1)"

	#echo "${python_libs}"

	if [ $(echo "${python_libs}" | grep 'pexpect' | wc -l) == 0 ]; then
		echo;
		error_message "Pexpect not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [ $(echo "${python_libs}" | grep 'SQLAlchemy' | wc -l) == 0 ]; then
		echo;
		error_message "SQLAlchemy not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [ $(echo "${python_libs}" | grep 'PyYAML' | wc -l) == 0 ]; then
		echo;
		error_message "PyYAML not installed!!!";
		read -n 1 -s -r -p "Press any key to exit...";
		exit 0;
	fi

	if [[ -f ${MAIN_PATH}/tmp/.tgui_mysql ]]; then
		rm ${MAIN_PATH}/tmp/.tgui_mysql
	fi

	echo "Done. Congratulation!"

	read -n 1 -s -r -p "Press any key to exit...";
	exit 0;
#fi

