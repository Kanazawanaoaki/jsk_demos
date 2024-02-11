import os
import argparse
from PIL import Image, ImageDraw
import json

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

def process_image(input_folder, output_folder):
    for filename in os.listdir(input_folder):
        if filename.endswith(".png"):
            print("load image file name:", filename)
            image_path = os.path.join(input_folder, filename)
            annotation_path = os.path.join(input_folder, filename.replace(".png", ".json"))

            if os.path.exists(annotation_path):
                image = Image.open(image_path)
                annotation = load_annotation(annotation_path)

                # アノテーションを画像に描画
                draw_annotation(image, annotation)

                # 出力フォルダに保存
                output_path = os.path.join(output_folder, filename.replace(".png", "_annotated.png"))
                image.save(output_path)

def main():
    parser = argparse.ArgumentParser(description="Process images with annotations")
    parser.add_argument("input_folder", help="Input folder containing PNG images and corresponding JSON annotations")
    parser.add_argument("output_folder", help="Output folder to save annotated images")
    args = parser.parse_args()

    input_folder = args.input_folder
    output_folder = args.output_folder

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print("made new dir in {}".format(output_folder))

    process_image(input_folder, output_folder)

if __name__ == "__main__":
    main()
