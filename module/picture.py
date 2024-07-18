import os
from time import sleep
from picamera2 import Picamera2

def take():
    directory = "img"
    name = os.path.join(directory, "object.jpg")
    picam2 = Picamera2()
    try:
        picam2.start_preview()
        picam2.start_and_capture_file(name)
        return True
    finally:
        picam2.stop_preview()
        picam2.close()