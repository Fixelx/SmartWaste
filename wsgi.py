import socket
from app import app

def get_ip_address():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0)
        s.connect(('10.254.254.254', 1))
        ip_address = s.getsockname()[0]
    except Exception:
        ip_address = '127.0.0.1'
    finally:
        s.close()
    
    return ip_address

if __name__ == "__main__":
    host_ip = get_ip_address()
    app.run(host=host_ip, port=8000)
