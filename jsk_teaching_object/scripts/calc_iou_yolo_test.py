#!/usr/bin/env python3

import os
import argparse
from PIL import Image, ImageDraw
import json
from ultralytics import YOLO
import numpy as np
import re

def load_annotation(annotation_path):
    with open(annotation_path, 'r') as f:
        annotation_data = json.load(f)
    return annotation_data

def draw_annotation(image, annotation):
    draw = ImageDraw.Draw(image)
    shapes = annotation.get('shapes', [])

    for shape in shapes:
        label = shape.get('label', '')
        points = shape.get('points', [])
        shape_type = shape.get('shape_type', 'rectangle')

        if shape_type == 'rectangle' and len(points) == 2:
            x1, y1 = points[0]
            x2, y2 = points[1]
            draw.rectangle([x1, y1, x2, y2], outline='red', width=2)
            draw.text((x1+5, y1+1), label, fill='red')

    return shapes


def check_rectangles_right(shape1, shape2):
    label1 = shape1.get('label', '')
    match = re.search(r'(\w+)', label1)
    if match:
        label1 = match.group(1)
    label2 = shape2.get('label', '')
    points1 = shape1.get('points', [])
    points2 = shape2.get('points', [])
    x1_left, y1_top = points1[0]
    x1_right, y1_bottom = points1[1]
    x2_left, y2_top = points2[0]
    x2_right, y2_bottom = points2[1]

    # 矩形1の右端が矩形2の左端より左にある場合、または矩形1の左端が矩形2の右端より右にある場合
    if x1_right < x2_left or x2_right < x1_left:
        return False

    # 矩形1の下端が矩形2の上端より上にある場合、または矩形1の上端が矩形2の下端より下にある場合
    if y1_bottom < y2_top or y2_bottom < y1_top:
        return False

    if label1 != label2:
        # print(label1, label2)
        return False

    # 上記の条件を満たさない場合、矩形は重なっている
    return True

def calc_iou(shape1, shape2):
    label1 = shape1.get('label', '')
    match = re.search(r'(\w+)', label1)
    if match:
        label1 = match.group(1)
    label2 = shape2.get('label', '')
    points1 = shape1.get('points', [])
    points2 = shape2.get('points', [])
    x1_left, y1_top = points1[0]
    x1_right, y1_bottom = points1[1]
    x2_left, y2_top = points2[0]
    x2_right, y2_bottom = points2[1]

    # 重なっている領域を計算
    intersection_x = max(0, min(x1_right, x2_right) - max(x1_left, x2_left))
    intersection_y = max(0, min(y1_bottom, y2_bottom) - max(y1_top, y2_top))
    intersection_area = intersection_x * intersection_y

    # 各矩形の面積を計算
    area_box1 = (x1_right - x1_left) * (y1_bottom - y1_top)
    area_box2 = (x2_right - x2_left) * (y2_bottom - y2_top)
    # print(area_box1, area_box2)

    # IOUを計算
    iou = float(intersection_area) / float(area_box1 + area_box2 - intersection_area)

    return label1, iou

def draw_result(image, results, target_names, ano_shapes, score_thresh=0.4):
    draw = ImageDraw.Draw(image)
    shapes = []

    # Extract bounding boxes from YOLO results and add to annotation
    if results:
        result = results[0]
    else:
        rospy.logerr("Error: The 'results' list is empty.")
        return

    valid_indices = []
    labels = []
    scores = []
    shapes = []
    for j, ((x1, y1, x2, y2), conf, cls) in enumerate(
            zip(result.boxes.xyxy, result.boxes.conf,
                result.boxes.cls)):
        if target_names[int(cls)] in ['others']:
            continue
        if conf < score_thresh:
            continue
        valid_indices.append(j)
        labels.append(int(cls))
        scores.append(float(conf))
        label = f'{target_names[int(cls)]} : {conf:.2f}'
        shapes.append({
            'label': label,
            'points': [(x1, y1), (x2, y2)],
            'shape_type': 'rectangle'
        })

    annotation_num = len(ano_shapes)
    detect_num = len(shapes)
    right_num = 0
    iou_dict_list = []
    for shape in shapes:
        label = shape.get('label', '')
        points = shape.get('points', [])
        shape_type = shape.get('shape_type', 'rectangle')

        if shape_type == 'rectangle' and len(points) == 2:
            x1, y1 = points[0]
            x2, y2 = points[1]

            right_flag = False
            for ano_shape in ano_shapes:
                if check_rectangles_right(shape, ano_shape):
                    # print("矩形1と矩形2は重なっています。")
                    right_flag = True
                    label1, iou = calc_iou(shape, ano_shape)
                    iou_dict = {}
                    iou_dict[label1] = "{:.2f}".format(iou)
                    iou_dict_list.append(iou_dict)
            if right_flag:
                draw_color = 'blue'
                right_num += 1
            else:
                draw_color = 'green'
            draw.rectangle([x1, y1, x2, y2], outline=draw_color, width=2)
            # draw.text((x1+5, y1+1), label, fill=draw_color)
            draw.text((x1+5, y1-11), label, fill=draw_color)

    results_dict = {"annotation_num": annotation_num,
                    "detect_num": detect_num,
                    "right_num": right_num,
                    "iou": iou_dict_list
    }
    return shapes, results_dict

def process_image(input_folder, output_folder, yolo_model_path):
    yolo_model = YOLO(yolo_model_path)
    target_names = [name for _, name in yolo_model.names.items()]

    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):
            image_path = os.path.join(input_folder, filename)
            annotation_path = os.path.join(input_folder, filename.replace(".png", ".json"))

            if os.path.exists(output_folder):
                image = Image.open(image_path)
                annotation = load_annotation(annotation_path)

                # Perform inference using YOLO model
                results = yolo_model(image_path)

                # Draw result and annotation on the image
                anno_shapes = draw_annotation(image, annotation)
                res_shapes, result_dict = draw_result(image, results, target_names, anno_shapes)

                # Save the annotated image to the output folder
                output_path = os.path.join(output_folder, filename.replace(".png", "_result.png"))
                image.save(output_path)

                result_output_path = os.path.join(output_folder, filename.replace(".png", "txt"))
                print(result_dict)
                with open(result_output_path, "w") as file:
                    for key, value in result_dict.items():
                        file.write(f"{key}: {value}\n")

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
