#!/bin/bash

# ANSI Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}Erfolg: $1${NC}"
}

print_error() {
    echo -e "${RED}Fehler: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}Info: $1${NC}"
}

#-->
#System Updaten
{ # try
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y ipcalc
    print_success "Systemupdate erfolgreich"
} || { # catch
    print_error "Fehler beim Systemupdate ist aufgetreten"
    exit 1
}


CURRENT_DATE_TIME=$(date +"%Y-%m-%d %H:%M:%S")
sudo timedatectl set-ntp false

if sudo date -s "$CURRENT_DATE_TIME"; then
    echo "Erfolg: Systemzeit erfolgreich auf $CURRENT_DATE_TIME gesetzt."
else
    echo "Fehler: Fehler beim Setzen der Systemzeit."
    exit 1
fi

sudo timedatectl set-ntp true

################################################################################################
################################################################################################
# OPTIONAL Netzwerkkonfiguration
get_network_info() {
    current_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    current_netmask=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+' | cut -d '/' -f 2)
    current_gateway=$(ip route | grep default | awk '{print $3}')
    current_nameserver=$(nmcli dev show eth0 | grep 'IP4.DNS' | awk '{print $2}')
}

netmask_to_dot() {
    IFS=. read -r i1 i2 i3 i4 <<< "$(ipcalc -m $current_ip/$current_netmask | cut -d= -f2)"
    echo "$i1.$i2.$i3.$i4"
}

read -p "Möchten Sie die IP-Adresse auf statisch setzen? (ja/nein): " set_static_ip

get_network_info

if [[ "$set_static_ip" =~ ^[Jj]$|^[Jj]a$ ]]; then
    current_netmask=$(netmask_to_dot)
    
    static_ip_config="
auto eth0
iface eth0 inet static
    address $current_ip
    netmask $current_netmask
    gateway $current_gateway
    dns-nameservers $current_nameserver 8.8.8.8
"
    {
        sudo cp /etc/network/interfaces /etc/network/interfaces.backup
        echo "$static_ip_config" | sudo tee /etc/network/interfaces > /dev/null
        sudo systemctl restart networking
        print_success "Netzwerkkonfiguration erfolgreich aktualisiert."
    } || {
        print_error "Fehler beim Setzen der IP aufgetreten."
        exit 1
    }
else
    print_info "Die Netzwerkkonfiguration wurde übersprungen."
fi
################################################################################################
################################################################################################


# git clone
{ # try
    github_repo="https://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@github.com/Fixelx/SmartWaste.git"
    if [ ! -d "$abs_path" ]; then
        directory_name="smartwaste"
        mkdir -p "$directory_name"
        abs_path="$(pwd)/$directory_name"
        git clone "$github_repo" "$abs_path"
        print_success "Git Clone erfolgreich"
    else
        print_error "Verzeichnis \"$abs_path\" existiert bereits."
    fi
} || { # catch
    print_error "Fehler beim Clonen von Github aufgetreten"
    exit 1
}


# Verzeichnisse erstellen
{ # try
    mkdir -p "$abs_path/log/gunicorn"
    mkdir -p "$abs_path/img"
    print_success "Verzeichnisstruktur erfolgreich erstellt"
} || { # catch
    print_error "Fehler beim Erstellen der Verzeichnisse aufgetreten"
    exit 1
}


#env erstellen
{ # try
    sudo python -m venv --system-site-packages "$abs_path/env"
    source "$abs_path/env/bin/activate"
    print_success "Virtual-Environment erfolgreich"
} || { # catch
    print_error "Fehler beim erstellen der Python Environment aufgetreten"
    exit 1
}

# Funktion zur Installation von Paketen und Protokollierung des Ergebnisses
install_packages() {
    local packages=("wheel" "numpy" "flask" "gunicorn" "gpiozero" "RPi.GPIO" "picamera2" "opencv-python" "cvzone" "tensorflow==2.13.0" "tflite-runtime" "libcamera-dev" "adafruit-circuitpython-ads1x15" "adafruit-blinka")
    local successful=()
    local failed=()

    for package in "${packages[@]}"; do
        if pip install "$package"; then
            successful+=("$package")
        else
            failed+=("$package")
        fi
    done

    if [ ${#successful[@]} -ne 0 ]; then
        print_success "Erfolgreich installierte Pakete: ${successful[*]}"
    fi

    if [ ${#failed[@]} -ne 0 ]; then
        print_error "Fehlgeschlagene Pakete: ${failed[*]}"
    fi

    if [ ${#failed[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

if install_packages; then
    print_success "Alle Python Pakete erfolgreich installiert"
else
    print_error "Fehler beim Installieren einiger Python Pakete mit pip aufgetreten"

    if ! python3 -c "import tensorflow as tf; print(tf.__version__)" &> /dev/null; then
        print_error "tensorflow konnte nicht installiert werden. Zusätzliche Abhängigkeiten werden installiert."

        sudo apt-get install libhdf5-dev
        sudo apt-get install -y build-essential

        # Erneut versuchen die Pakete zu installieren
        if install_packages; then
            print_success "Alle Python Pakete erfolgreich installiert nach der Installation zusätzlicher Abhängigkeiten"
        else
            print_error "Fehler beim erneuten Installieren einiger Python Pakete mit pip"
            exit 1
        fi
    else
        print_error "Ein anderer Fehler ist aufgetreten."
        exit 1
    fi
fi



# Berechtigungen anpassen
{ # try
    if grep -q "^smartwaste_dev:" /etc/group; then
        print_info "Die Gruppe 'smartwaste_dev' existiert bereits."
    else
        sudo groupadd smartwaste_dev
    fi
    sudo chmod -R 774 "$directory_name"
    sudo chown -R root:smartwaste_dev "$directory_name"
    print_success "Berechtigungen erfolgreich angepasst"
} || { # catch
    print_error "Fehler beim Setzen der Berechtigungen aufgetreten"
    exit 1
}


#libcamera installieren
{ # try
    sudo apt install -y python3-libcamera
    print_success "Packet:libcamera erfolgreich"
} || { # catch
    print_error "Fehler beim installieren des Pakets:libcamera aufgetreten"
    exit 1
}


##NGINX KONFIGURATION
#NGINX installieren
{ # try
    sudo apt-get install -y nginx
    print_success "Packet:nginx erfolgreich"
} || { # catch
    print_error "Fehler beim installieren des Pakets:nginx aufgetreten"
    exit 1
}


#Verzeichnisse verschieben und verlinken
{ # try
    nginx_config="
server {
    listen 80;
    server_name $current_ip;  # Die aktuelle IP-Adresse des Servers

    location / {
        proxy_pass http://$current_ip:8000;  # Die Adresse, unter der Gunicorn läuft
        include /etc/nginx/proxy_params;
        proxy_redirect off;
    }

    location /static {
        alias $abs_path/www/static;  # Pfad zu deinen statischen Dateien
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
"
    echo "$nginx_config" | sudo tee /etc/nginx/sites-available/smartwaste > /dev/null
    sudo ln -sf /etc/nginx/sites-available/smartwaste /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    print_success "Nginx-Konfiguration erfolgreich aktualisiert."
} || { # catch
    print_error "Fehler beim Verschieben und Verlinken der Verzeichnisse aufgetreten"
    exit 1
}


#NGINX überprüfen
print_info "NGINX instalation wird überprüft: "
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
    print_error "NGINX Konfiguration konnte nicht überprüft werden. Beende Setup."
    exit 1
fi


# Gunicorn konfigurieren
{ # try
    service_file="/etc/systemd/system/gunicorn.service"
    service_config="
[Unit]
Description=gunicorn daemon for SmartWaste
After=network.target

[Service]
User=www-data
Group=www-data

WorkingDirectory=$abs_path
ExecStart=/home/Felix/smartwaste/env/bin/gunicorn --workers 3 --bind $current_ip:8000 --access-logfile /home/Felix/smartwaste/log/gunicorn/access.log --error-logfile /home/Felix/smartwaste/log/gunicorn/error.log app:app

# Restart policies
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
"
    echo "$service_config" | sudo tee $service_file > /dev/null
    print_success "Gunicorn-Service erfolgreich aktualisiert und neu gestartet."
} || { # catch
        print_error "Fehler beim Verschieben der Datei gunicorn.service aufgetreten"
        exit 1
}


# Audiotreiber installieren
{
    git clone https://github.com/waveshare/WM8960-Audio-HAT
    cd WM8960-Audio-HAT || { print_error "Verzeichniswechsel fehlgeschlagen"; exit 1; }

    if sudo ./install.sh; then
        print_success "Audiotreiber erfolgreich installiert"
    else
        print_error "Fehler bei der Installation des Audiotreibers"
        exit 1
    fi

    # Überprüfen, ob der Treiber geladen ist
    if lsmod | grep -q wm8960; then
        print_success "Treiber ist geladen"
    else
        print_error "Treiber ist nicht geladen"
        exit 1
    fi

    # Neustarten der betroffenen Dienste
    if sudo systemctl restart alsa-state && sudo systemctl restart pulseaudio; then
        print_success "Dienste erfolgreich neu gestartet"
    else
        print_error "Fehler beim Neustarten der Dienste"
        exit 1
    fi

    print_info "Überprüfen Sie die Audioausgabe, um sicherzustellen, dass alles funktioniert."
} || {
    print_error "Fehler beim Installieren des Audiotreibers aufgetreten"
    exit 1
}

#L2C aktivieren
{
# Erstellen einer temporären Konfigurationsdatei für raspi-config
    CONFIG_SCRIPT=$(mktemp /tmp/raspi-config-run.XXXXXX.sh)

    # Schreiben der automatisierten raspi-config Optionen in die temporäre Datei
    cat <<'EOF' > "$CONFIG_SCRIPT"
# Raspi-config Automatisierung
raspi-config nonint do_i2c 0
EOF

    # Ausführen der Konfigurationsdatei
    if sudo bash "$CONFIG_SCRIPT"; then
        print_success "I2C wurde aktiviert."
    else
        print_error "Fehler beim Ausführen von raspi-config."
        rm "$CONFIG_SCRIPT"
        exit 1
    fi

    # Löschen der temporären Konfigurationsdatei
    rm "$CONFIG_SCRIPT"
} || {
    print_error "Fehler beim Erstellen oder Ausführen des Konfigurationsskripts."
    exit 1
}


#Gunicorn starten
{ # try
    sudo systemctl daemon-reload
    sudo systemctl start gunicorn
    sudo systemctl enable gunicorn
    print_success "Gunicorn erfolgreich gestartet"
    print_info "Mit \"sudo systemctl start gunicorn\" lässt sich der Service starten."
} || { # catch
    print_error "Fehler beim starten von Gunicorn aufgetreten"
    exit 1
}


#Setup abschließen
sudo rm "setup.sh"
sleep 5
sudo systemctl status gunicorn
print_success "Setup abgeschlossen"
print_info "Ein Neustart des Systems kann erforderlich sein, um alle Änderungen vollständig zu übernehmen."
