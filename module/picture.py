from time import sleep
from picamera2 import Picamera2, Preview
import os

def take():
    name="test.jpg"
    picam2 = Picamera2()
    picam2.start_and_capture_file(name)
    picam2.close()
    return True
