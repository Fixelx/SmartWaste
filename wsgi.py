# /home/SmartWaste/wsgi.py
from app import app

if __name__ == "__main__":
    app.run(host='192.168.1.31', port=8000)
