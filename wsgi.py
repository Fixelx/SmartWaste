import socket
from app import app

def get_ip_address():
    # Versuche, die IP-Adresse des Geräts zu ermitteln
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0)
        s.connect(('10.254.254.254', 1))  # Eine nicht erreichbare IP-Adresse
        ip_address = s.getsockname()[0]
    except Exception:
        ip_address = '127.0.0.1'  # Fallback zu localhost
    finally:
        s.close()
    
    return ip_address

if __name__ == "__main__":
    host_ip = get_ip_address()
    app.run(host=host_ip, port=8000)
