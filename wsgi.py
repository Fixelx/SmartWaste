# /home/SmartWaste/wsgi.py
from app import app

if __name__ == "__main__":
    app.run(host='10.4.65.53', port=8000)
