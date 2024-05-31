#!/usr/bin/env python

import argparse
import os
import shutil
import cv2
import pickle

def process_image(input_path, output_dir, datastamp):
    print(input_path)
    if input_path.endswith('tracking_depth_raw.pkl'):
        # Process pickle file
        with open(input_path, 'rb') as f:
            data = pickle.load(f)
        # Example processing for pickle data: You can add your processing code here
        processed_data = data

        # Save the processed data
        output_subdir = os.path.join(output_dir, "depth")
        os.makedirs(output_subdir, exist_ok=True)
        output_file_name = f"{datastamp}.png"
        output_path = os.path.join(output_subdir, output_file_name)
        print(output_path)
        cv2.imwrite(output_path, processed_data)

    elif input_path.endswith('tracking_image_rect_color.png'):
        # Process image file
        image = cv2.imread(input_path)
        # Save the processed image
        output_subdir = os.path.join(output_dir, "rgb")
        os.makedirs(output_subdir, exist_ok=True)
        output_file_name = f"{datastamp}.png"
        output_path = os.path.join(output_subdir, output_file_name)
        print(output_path)
        cv2.imwrite(output_path, image)
    else:
        # Process image file
        image = cv2.imread(input_path)
        # Example processing: Convert the image to grayscale
        gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        # Save the processed image
        output_subdir = os.path.join(output_dir, "mask")
        os.makedirs(output_subdir, exist_ok=True)
        output_file_name = f"{datastamp}.png"
        output_path = os.path.join(output_subdir, output_file_name)
        print(output_path)
        cv2.imwrite(output_path, gray_image)

def process_files(input_dir, output_dir, file_names):
    for datastamp in os.listdir(input_dir):
        if os.path.isdir(os.path.join(input_dir, datastamp)):
            dir_path = os.path.join(input_dir, datastamp)
            for file_name in file_names:
                src_path = os.path.join(dir_path, file_name)
                if os.path.exists(src_path):
                    # Process image file
                    process_image(src_path, output_dir, datastamp)
                    print(f"Processed and copied {file_name} from {datastamp}")

def main():
    parser = argparse.ArgumentParser(description='Process files in specified directories.')
    parser.add_argument('input_dir', type=str, help='Input directory containing subdirectories with files')
    parser.add_argument('output_dir', type=str, help='Output directory to save processed files')
    parser.add_argument('--file_names', nargs='+', default=['tracking_depth_raw.pkl', 'tracking_image_rect_color.png', 'tracking_mask_image.png'], help='Names of files to process')

    args = parser.parse_args()

    input_dir = args.input_dir
    output_dir = args.output_dir
    file_names = args.file_names

    process_files(input_dir, output_dir, file_names)

if __name__ == "__main__":
    main()
