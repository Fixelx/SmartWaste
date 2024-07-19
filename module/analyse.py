import cv2
import numpy as np
from tflite_runtime.interpreter import Interpreter

interpreter = Interpreter(model_path='module/model/model.tflite')
interpreter.allocate_tensors()

def preprocess_image(image_path, target_size):
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError(f"Bild konnte nicht geladen werden: {image_path}")
    image = cv2.resize(image, target_size)
    image = image.astype(np.float32) / 255.0
    return image[np.newaxis, ...]

def predict_with_tflite(interpreter, image):
    input_details = interpreter.get_input_details()[0]
    output_details = interpreter.get_output_details()[0]

    interpreter.set_tensor(input_details['index'], image)
    interpreter.invoke()

    output_data = interpreter.get_tensor(output_details['index'])
    return output_data

def erkennen(image_path):
    image = preprocess_image(image_path, (224, 224))
    output = predict_with_tflite(interpreter, image)

    with open('module/model/labels.txt', 'r') as f:
        class_names = [line.strip() for line in f.readlines()]

    index = np.argmax(output)
    best_label = class_names[index] if index < len(class_names) else "Unbekannt"

    return best_label
