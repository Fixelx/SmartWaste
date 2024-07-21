from flask import Flask, render_template, jsonify
from module.picture import *
from module.analyse import *
from module.battery import *
import RPi.GPIO as GPIO

app = Flask(__name__, template_folder='www', static_folder='www/static')

@app.route('/')
def index():
    return render_template('index.html')

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
    return render_template('battery.html')

@app.route('/battery_status')
def battery_status():
    data = get_battery_status()
    print(data)
    return jsonify(data)

if __name__ == '__main__':
    app.run()
