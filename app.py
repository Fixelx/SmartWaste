from flask import Flask, render_template
from module.picture import *
import RPi.GPIO as GPIO  # Falls GPIO benötigt wird

app = Flask(__name__, template_folder='/home/SmartWaste/project/www')

# GPIO Setup (falls benötigt)
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
    if take():  
        return "True"
    else:
        return "False"

if __name__ == '__main__':
    app.run()
