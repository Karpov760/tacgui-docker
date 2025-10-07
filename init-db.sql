CREATE DATABASE IF NOT EXISTS tgui;
CREATE DATABASE IF NOT EXISTS tgui_log;

CREATE USER 'tgui_user'@'%' IDENTIFIED WITH mysql_native_password BY 'some_password';
GRANT ALL PRIVILEGES ON *.* TO 'tgui_user'@'%' WITH GRANT OPTION;
