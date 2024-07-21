import os
from picamera2 import Picamera2, Preview

def take():
    directory = "img"
   
    name = os.path.join(directory, "object.jpg")
    picam2 = Picamera2()

    try:
        # Konfiguration für die Aufnahme
        picam2.configure(picam2.create_still_configuration())
        picam2.start()
        
        # Direktes Bild aufnehmen
        picam2.capture_file(name)

    finally:
        picam2.stop()
        picam2.close()

    return name
