import Adafruit_ADS1x15

# Initialisiere den ADC
adc = Adafruit_ADS1x15.ADS1115(busnum=1)

# Konfiguration
GAIN = 1

# Schwellenwerte
VOLTAGE_MIN = 0.8  # Niedrigster Wert für 0%
VOLTAGE_MAX = 1.5  # Höchster Wert für 100%
NO_CONNECTION_THRESHOLD = 0.3  # Schwellenwert für keine Verbindung

# Widerstandswerte für den Spannungsteiler
RESISTOR1 = 9000  # Widerstand1 in Ohm
RESISTOR2 = 9000  # Widerstand2 in Ohm
VREF = 4.096  # Referenzspannung des ADC in Volt

def read_voltage(channel):
    """Lese die Spannung am angegebenen Kanal aus und berücksichtige den Spannungsteiler."""
    value = adc.read_adc(channel, gain=GAIN)
    # Berechne die Spannung in Volt und multipliziere mit 2, um die tatsächliche Spannung zu erhalten
    measured_voltage = value * VREF / 32767
    actual_voltage = measured_voltage * ((RESISTOR1 + RESISTOR2) / RESISTOR2)
    return actual_voltage

def calculate_percentage(voltage):
    """Berechne die Prozentzahl basierend auf der Spannung."""
    if voltage < NO_CONNECTION_THRESHOLD:
        return None  # Kein angeschlossenes Gerät erkannt
    elif voltage < VOLTAGE_MIN:
        return 0
    elif voltage > VOLTAGE_MAX:
        return 100
    else:
        # Berechne die Prozentzahl als interpolierten Wert
        percentage = (voltage - VOLTAGE_MIN) / (VOLTAGE_MAX - VOLTAGE_MIN) * 100
        return round(percentage, 2)

def get_battery_status():
    """Lese den Status für alle Kanäle aus und berechne die Spannung und Prozentzahl."""
    battery_status = {}
    for channel in range(4):
        voltage = read_voltage(channel)
        # Füge Debug-Ausgaben hinzu
        percentage = calculate_percentage(voltage)
        battery_status[f'battery{channel + 1}'] = {
            'voltage': round(voltage, 2),
            'percentage': percentage
        }
    return battery_status
