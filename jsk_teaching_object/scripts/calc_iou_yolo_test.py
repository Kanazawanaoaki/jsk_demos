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
    valid_indices = []
    labels = []
    scores = []
    for j, ((x1, y1, x2, y2), conf, cls) in enumerate(
            zip(result.boxes.xyxy, result.boxes.conf,
                result.boxes.cls)):
        if self.target_names[int(cls)] in self.ignore_class_names:
            continue
        if conf < self.score_thresh:
            continue
        valid_indices.append(j)
        print(x1, y1, x2, y2)
        # rects_msg.rects.append(
        #     Rect(x=int(x1), y=int(y1),
        #          width=int(x2 - x1), height=int(y2 - y1)))
        labels.append(int(cls))
        scores.append(float(conf))
        label = f'Class {int(cls)} - Confidence: {conf:.2f}'
        annotation['shapes'].append({
            'label': label,
            'points': [(x1, y1), (x2, y2)],
            'shape_type': 'rectangle'
        })


    # for boxes in results[0].boxes:
    #     box = boxes.xyxy[0].numpy()
    #     x1, y1, x2, y2, confidence, class_index = box
    #     label = f'Class {int(class_index)} - Confidence: {confidence:.2f}'
    #     annotation['shapes'].append({
    #         'label': label,
    #         'points': [(x1, y1), (x2, y2)],
    #         'shape_type': 'rectangle'
    #     })

    for shape in shapes:
        label = shape.get('label', '')
        points = shape.get('points', [])
        shape_type = shape.get('shape_type', 'rectangle')

        if shape_type == 'rectangle' and len(points) == 2:
            x1, y1 = points[0]
            x2, y2 = points[1]
            draw.rectangle([x1, y1, x2, y2], outline='green', width=2)
            draw.text((x1, y1), label, fill='green')

def process_image(input_folder, output_folder, yolo_model_path):
    yolo_model = YOLO(yolo_model_path)

    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):
            image_path = os.path.join(input_folder, filename)

            if os.path.exists(output_folder):
                image = Image.open(image_path)

                # Perform inference using YOLO model
                results = yolo_model(image_path)

                # Draw annotation on the image
                draw_result(image, results)

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

    process_image(input_folder, output_folder, yolo_model_path)

if __name__ == "__main__":
    main()
