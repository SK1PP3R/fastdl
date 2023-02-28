#!/bin/bash
if [ ! "$(id -u steam)" -eq "$UID" ]; then 
        usermod -o -u "$UID" steam ; 
fi
if [ ! "$(id -g steam)" -eq "$GID" ]; then 
        groupmod -o -g "$GID" steam ; 
fi

# Lesen Sie den Servernamen aus der Umgebungsvariable $SERVERNAME
SERVERNAME="${SERVERNAME}"

# Lesen Sie den SSL-Flag aus der Umgebungsvariable $SSL_ENABLED
SSL_ENABLED="${SSL_ENABLED:-true}"

# Lesen Sie den Indexes-Flag aus der Umgebungsvariable $INDEXES
INDEXES="${INDEXES:-true}"

# Lesen Sie den Pfad zur SSL-Datei aus der Umgebungsvariable $SSL_PATH
SSL_PATH="${SSL_PATH:-/etc/apache2/ssl}"

# Pfad zur Konfigurationsdatei erstellen
CONFIG_FILE="/etc/apache2/sites-available/000-default.conf"

# Überprüfen, ob die Konfigurationsdatei bereits existiert
if [ -e "$CONFIG_FILE" ]; then
  echo "Configuration file already exists: $CONFIG_FILE"
  echo "Deleting existing configuration file..."
  rm "$CONFIG_FILE"
fi

# Konfigurieren Sie den Options- und AllowOverride-Wert basierend auf der Umgebungsvariable $INDEXES
if [ "$INDEXES" = false ]; then
  OPTIONS="-Indexes"
  ALLOW_OVERRIDE="None"
else
  OPTIONS="Indexes FollowSymLinks MultiViews"
  ALLOW_OVERRIDE="All"
fi

# Konfigurieren Sie die SSL-Zertifikats- und Schlüsseldateien basierend auf der Umgebungsvariable $SSL_PATH
if [ "$SSL_ENABLED" = true ]; then
  SSL_CERT_FILE="$SSL_PATH/$SERVERNAME.cert.pem"
  SSL_KEY_FILE="$SSL_PATH/$SERVERNAME.privkey.pem"
else
  SSL_CERT_FILE=""
  SSL_KEY_FILE=""
fi

# Erstellen Sie einen VirtualHost mit Port 80 und Weiterleitung auf HTTPS, wenn SSL aktiviert ist
if [ "$SSL_ENABLED" = true ]; then
  cat <<EOF > "$CONFIG_FILE"
<IfModule mod_ssl.c>
<VirtualHost *:80>
    ServerName $SERVERNAME
    RewriteEngine On
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
<VirtualHost *:443>
    ServerName $SERVERNAME
    DocumentRoot /var/www
    <Directory /var/www>
        Options $OPTIONS
        AllowOverride $ALLOW_OVERRIDE
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SSLEngine on
    SSLCertificateFile $SSL_CERT_FILE
    SSLCertificateKeyFile $SSL_KEY_FILE
</VirtualHost>
</IfModule>
EOF
  echo "Configuration file created: $CONFIG_FILE (SSL)"
# Erstellen Sie einen VirtualHost mit Port 80 und Weiterleitung auf HTTPS, wenn SSL deaktiviert ist
else
  cat <<EOF > "$CONFIG_FILE"
<VirtualHost *:80>
    ServerName $SERVERNAME
    DocumentRoot /var/www
    <Directory /var/www>
        Options $OPTIONS
        AllowOverride $ALLOW_OVERRIDE
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
  echo "Configuration file created: $CONFIG_FILE (Port 80)"
fi
chown -R steam:steam /var/www
/etc/init.d/apache2 restart
tail -f /var/log/apache2/error.log
