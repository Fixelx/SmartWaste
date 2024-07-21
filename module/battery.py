import Adafruit_ADS1x15

# Initialisiere den ADC
adc = Adafruit_ADS1x15.ADS1115(busnum=1)

# Konfiguration
GAIN = 1

# Schwellenwerte
VOLTAGE_MIN = 0.8
VOLTAGE_MAX = 1.5
NO_CONNECTION_THRESHOLD = 0.3

def read_voltage(channel):
    """Lese die Spannung am angegebenen Kanal aus."""
    value = adc.read_adc(channel, gain=GAIN)
    voltage = value * 4.096 / 32767
    return voltage

def calculate_percentage(voltage):
    """Berechne die Prozentzahl basierend auf der Spannung."""
    if voltage < NO_CONNECTION_THRESHOLD:
        return None
    elif voltage < VOLTAGE_MIN:
        return 0
    elif voltage > VOLTAGE_MAX:
        return 100
    else:
        percentage = (voltage - VOLTAGE_MIN) / (VOLTAGE_MAX - VOLTAGE_MIN) * 100
        return round(percentage, 2)

def get_battery_status():
    """Lese den Status für alle Kanäle aus und berechne die Spannung und Prozentzahl."""
    battery_status = {}
    for channel in range(4):
        voltage = read_voltage(channel)
        percentage = calculate_percentage(voltage)
        battery_status[f'battery{channel + 1}'] = {
            'voltage': round(voltage, 2),
            'percentage': percentage
        }
    return battery_status
