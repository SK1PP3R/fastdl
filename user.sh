#!/bin/sh
if [ ! "$(id -u www)" -eq "$UID" ]; then 
        usermod -o -u "$UID" www ; 
fi
if [ ! "$(id -g www)" -eq "$GID" ]; then 
        groupmod -o -g "$GID" www ; 
fi

if [ ! -d "/var/www/server_$SERVER_ID" ]; then
  mkdir /var/www/server_$SERVER_ID >/dev/null 2>&1
fi
