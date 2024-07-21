import Adafruit_ADS1x15

# Create an ADS1115 ADC (analog-to-digital converter) instance on I2C bus 1
adc = Adafruit_ADS1x15.ADS1115(busnum=1)

# Gain setting, 1x means +-4.096V
GAIN = 1

# Voltage range for the battery (adjust according to your battery type)
# Example for Alkaline batteries:
VOLTAGE_MIN = 0.8
VOLTAGE_MAX = 1.5

def read_voltage(channel):
    # Read the value from the specified channel
    value = adc.read_adc(channel, gain=GAIN)
    # Convert the reading to voltage
    voltage = value * 4.096 / 32767
    return voltage

def calculate_percentage(voltage):
    # Calculate the percentage based on the voltage range
    if voltage < VOLTAGE_MIN:
        return 0
    elif voltage > VOLTAGE_MAX:
        return 100
    else:
        percentage = (voltage - VOLTAGE_MIN) / (VOLTAGE_MAX - VOLTAGE_MIN) * 100
        return round(percentage, 2)

def get_battery_status():
    battery_status = {}
    for channel in range(4):
        voltage = read_voltage(channel)
        percentage = calculate_percentage(voltage)
        battery_status[f'battery{channel + 1}'] = {
            'voltage': round(voltage, 2),
            'percentage': round(percentage, 2)
        }
    return battery_status
