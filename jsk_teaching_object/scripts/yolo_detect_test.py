#!/usr/bin/env python3

import os
import argparse
from PIL import Image, ImageDraw
import json
from ultralytics import YOLO
import numpy as np

def load_annotation(annotation_path):
    with open(annotation_path, 'r') as f:
        annotation_data = json.load(f)
    return annotation_data

def draw_result(image, results):
    draw = ImageDraw.Draw(image)
    shapes = []

    # Extract bounding boxes from YOLO results and add to annotation
    if results:
        result = results[0]
    else:
        rospy.logerr("Error: The 'results' list is empty.")
        return

    # import ipdb
    # ipdb.set_trace()

    # result_array = np.array(result.plot())
    # result_image = Image.fromarray(result_array)

    result_array_bgr = np.array(result.plot())
    result_array_rgb = result_array_bgr[..., ::-1]
    result_image = Image.fromarray(result_array_rgb)

    image = result_image
    return image

def process_image(input_folder, output_folder, yolo_model_path):
    yolo_model = YOLO(yolo_model_path)

    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):
            image_path = os.path.join(input_folder, filename)

            if os.path.exists(output_folder):
                image = Image.open(image_path)

                # Perform inference using YOLO model
                results = yolo_model(image_path)

                # Draw result on the image
                image = draw_result(image, results)

                # Save the annotated image to the output folder
                output_path = os.path.join(output_folder, filename.replace(".png", "_result.png"))
                image.save(output_path)

def main():
    parser = argparse.ArgumentParser(description="Process images with annotations")
    parser.add_argument("input_folder", help="Input folder containing PNG images and corresponding JSON annotations")
    parser.add_argument("output_folder", help="Output folder to save annotated images")
    parser.add_argument("yolo_model_path", help="Path to the YOLO model file")
    args = parser.parse_args()

    input_folder = args.input_folder
    output_folder = args.output_folder
    yolo_model_path = args.yolo_model_path

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print("made new dir in {}".format(output_folder))

    process_image(input_folder, output_folder, yolo_model_path)

if __name__ == "__main__":
    main()
