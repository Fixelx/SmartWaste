#!/bin/bash

# ANSI Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funktion zum Ausgeben in Grün
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Funktion zum Ausgeben in Rot
print_error() {
    echo -e "${RED}$1${NC}"
}



# Ziel-Pfad für die Netzwerkkonfigurationsdatei
interfaces_file="/etc/network/interfaces"

# Aktuelle IP-Adresse abrufen (für eth0)
current_ip=$(ip -o -4 addr show eth0 | awk '{split($4,a,"/"); print a[1]}')

# Statische IP-Konfiguration, die eingetragen werden soll
static_ip_config="
iface eth0 inet static
    address $current_ip
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1 8.8.8.8
"

# Backup der aktuellen Datei erstellen
sudo cp "$interfaces_file" "$interfaces_file.backup"

# Datei leeren und neue Konfiguration einfügen
sudo echo "$static_ip_config" > "$interfaces_file"

# Ausgabe zur Bestätigung
print_success "Netzwerkkonfiguration erfolgreich in '$interfaces_file' aktualisiert"








# Verzeichnisname, das erstellt werden soll
directory_name="smartwaste"

# GitHub Repository URL
github_repo="https://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@github.com/Fixelx/SmartWaste.git"


# Schritt 1: Verzeichnis erstellen, wenn es nicht existiert
if [ ! -d "$directory_name" ]; then
    mkdir -p "$directory_name"
    abs_path="$(pwd)/$directory_name"
    print_success "Absoluter Pfad von \"$directory_name\": $abs_path"
    print_success "Verzeichnis \"$directory_name\" erfolgreich erstellt."
else
    print_success "Verzeichnis \"$directory_name\" existiert bereits."
fi

# Schritt 2: Ins Verzeichnis wechseln
cd "$abs_path"

# Schritt 3: GitHub Repository klonen
git clone "$github_repo" "$abs_path"
if [ $? -eq 0 ]; then
    print_success "GitHub Repository erfolgreich geklont."
else
    print_error "Fehler beim Klonen des GitHub Repositorys."
    exit 1
fi

# Schritt 4: Benötigte Ordner erstellen (log und log/gunicorn)
mkdir -p log/gunicorn
print_success "Verzeichnisse \"log\" und \"log/gunicorn\" erfolgreich erstellt."

# Schritt 5: Python Virtual Environment (venv) erstellen und aktivieren
python3 -m venv --system-site-packages "$abs_path"/env
source "$abs_path"/env/bin/activate
print_success "Python Virtual Environment \"env\" erfolgreich erstellt und aktiviert."

# Schritt 6: Pakete installieren über pip
pip3 install wheel numpy flask gunicorn gpiozero RPi.GPIO picamera2
if [ $? -eq 0 ]; then
    print_success "Pakete wheel, numpy, flask, gunicorn, gpiozero, RPi.GPIO, picamera2 erfolgreich installiert."
else
    print_error "Fehler beim Installieren der Pakete."
    exit 1
fi

sudo apt-get update
sudo apt install -y python3-libcamera

# Schritt 7: NGINX installieren

sudo apt-get install -y nginx
if [ $? -eq 0 ]; then
    print_success "NGINX erfolgreich installiert."
else
    print_error "Fehler beim Installieren von NGINX."
    exit 1
fi

# Schritt 8: NGINX Konfigurationsdatei aus dem Git-Repository kopieren
if [ -f "temp/smartwaste" ]; then
    sudo mv temp/smartwaste /etc/nginx/sites-available/smartwaste
    if [ $? -eq 0 ]; then
        print_success "NGINX Konfigurationsdatei erfolgreich nach /etc/nginx/sites-available/smartwaste kopiert."
    else
        print_error "Fehler beim Kopieren der NGINX Konfigurationsdatei."
        exit 1
    fi
else
    print_error "Die Datei temp/smartwaste existiert nicht. Überprüfen Sie die Existenz und den Pfad der Datei."
    exit 1
fi

# Schritt 9: Konfigurationsdatei in sites-enabled verlinken, falls noch nicht vorhanden
if [ ! -e /etc/nginx/sites-enabled/smartwaste ]; then
    sudo ln -s /etc/nginx/sites-available/smartwaste /etc/nginx/sites-enabled/
    if [ $? -eq 0 ]; then
        print_success "NGINX Konfigurationsdatei erfolgreich in sites-enabled verlinkt."
    else
        print_error "Fehler beim Erstellen des symbolischen Links für die NGINX Konfigurationsdatei."
        exit 1
    fi
fi

# Schritt 10: NGINX Konfiguration überprüfen und Neu laden
print_success "Überprüfe NGINX Konfiguration..."
sudo nginx -t
nginx_status=$?

if [ $nginx_status -eq 0 ]; then
    print_success "NGINX Konfiguration ist gültig. Starte und lade NGINX neu..."
    sudo systemctl start nginx
    if [ $? -eq 0 ]; then
        sudo systemctl reload nginx
        if [ $? -eq 0 ]; then
            print_success "NGINX Konfiguration erfolgreich neu geladen."
        else
            print_error "Fehler beim Neuladen der NGINX Konfiguration."
            exit 1
        fi
    else
        print_error "Fehler beim Starten von NGINX."
        exit 1
    fi
else
    print_error "Fehler: NGINX Konfiguration konnte nicht überprüft werden. Beende Setup."
    exit 1
fi

# Schritt 11: Gunicorn Service-Datei verschieben und Service starten
sudo mv "$abs_path/temp/gunicorn.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl stop gunicorn
print_success "Server produktiv starten mit: sudo systemctl start gunicorn"

source "$abs_path/env/bin/activate"
python3 wsgi.py

deactivate
sudo rm -rf "$abs_path/temp"
print_success "Setup abgeschlossen."