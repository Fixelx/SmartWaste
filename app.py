from flask import Flask, render_template
from module.picture import *
from module.analyse import *
from module.battery import *
import RPi.GPIO as GPIO

app = Flask(__name__, template_folder='www/', static_folder='www/static')

LED_PIN = 17
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(LED_PIN, GPIO.OUT)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/led/<action>')
def led_action(action):
    if action == 'on':
        GPIO.output(LED_PIN, GPIO.HIGH)
    elif action == 'off':
        GPIO.output(LED_PIN, GPIO.LOW)
    return 'LED ' + action

@app.route('/start')
def start():
    image_path = take()
    if image_path:
        result = erkennen(image_path)
        return result
    else:
        return "Fehler beim Aufnehmen des Bildes"

@app.route('/battery')
def battery():
    battery1, battery2, battery3, battery4 = getBatteryStat()
    return render_template('battery.html', battery1=battery1, battery2=battery2, battery3=battery3, battery4=battery4)

if __name__ == '__main__':
    app.run()
