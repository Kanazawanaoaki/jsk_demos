#!/usr/bin/env python3

import argparse
import os
import re
import cv2
import numpy as np


DAVIS_PALETTE = b"\x00\x00\x00\x80\x00\x00\x00\x80\x00\x80\x80\x00\x00\x00\x80\x80\x00\x80\x00\x80\x80\x80\x80\x80@\x00\x00\xc0\x00\x00@\x80\x00\xc0\x80\x00@\x00\x80\xc0\x00\x80@\x80\x80\xc0\x80\x80\x00@\x00\x80@\x00\x00\xc0\x00\x80\xc0\x00\x00@\x80\x80@\x80\x00\xc0\x80\x80\xc0\x80@@\x00\xc0@\x00@\xc0\x00\xc0\xc0\x00@@\x80\xc0@\x80@\xc0\x80\xc0\xc0\x80\x00\x00@\x80\x00@\x00\x80@\x80\x80@\x00\x00\xc0\x80\x00\xc0\x00\x80\xc0\x80\x80\xc0@\x00@\xc0\x00@@\x80@\xc0\x80@@\x00\xc0\xc0\x00\xc0@\x80\xc0\xc0\x80\xc0\x00@@\x80@@\x00\xc0@\x80\xc0@\x00@\xc0\x80@\xc0\x00\xc0\xc0\x80\xc0\xc0@@@\xc0@@@\xc0@\xc0\xc0@@@\xc0\xc0@\xc0@\xc0\xc0\xc0\xc0\xc0 \x00\x00\xa0\x00\x00 \x80\x00\xa0\x80\x00 \x00\x80\xa0\x00\x80 \x80\x80\xa0\x80\x80`\x00\x00\xe0\x00\x00`\x80\x00\xe0\x80\x00`\x00\x80\xe0\x00\x80`\x80\x80\xe0\x80\x80 @\x00\xa0@\x00 \xc0\x00\xa0\xc0\x00 @\x80\xa0@\x80 \xc0\x80\xa0\xc0\x80`@\x00\xe0@\x00`\xc0\x00\xe0\xc0\x00`@\x80\xe0@\x80`\xc0\x80\xe0\xc0\x80 \x00@\xa0\x00@ \x80@\xa0\x80@ \x00\xc0\xa0\x00\xc0 \x80\xc0\xa0\x80\xc0`\x00@\xe0\x00@`\x80@\xe0\x80@`\x00\xc0\xe0\x00\xc0`\x80\xc0\xe0\x80\xc0 @@\xa0@@ \xc0@\xa0\xc0@ @\xc0\xa0@\xc0 \xc0\xc0\xa0\xc0\xc0`@@\xe0@@`\xc0@\xe0\xc0@`@\xc0\xe0@\xc0`\xc0\xc0\xe0\xc0\xc0\x00 \x00\x80 \x00\x00\xa0\x00\x80\xa0\x00\x00 \x80\x80 \x80\x00\xa0\x80\x80\xa0\x80@ \x00\xc0 \x00@\xa0\x00\xc0\xa0\x00@ \x80\xc0 \x80@\xa0\x80\xc0\xa0\x80\x00`\x00\x80`\x00\x00\xe0\x00\x80\xe0\x00\x00`\x80\x80`\x80\x00\xe0\x80\x80\xe0\x80@`\x00\xc0`\x00@\xe0\x00\xc0\xe0\x00@`\x80\xc0`\x80@\xe0\x80\xc0\xe0\x80\x00 @\x80 @\x00\xa0@\x80\xa0@\x00 \xc0\x80 \xc0\x00\xa0\xc0\x80\xa0\xc0@ @\xc0 @@\xa0@\xc0\xa0@@ \xc0\xc0 \xc0@\xa0\xc0\xc0\xa0\xc0\x00`@\x80`@\x00\xe0@\x80\xe0@\x00`\xc0\x80`\xc0\x00\xe0\xc0\x80\xe0\xc0@`@\xc0`@@\xe0@\xc0\xe0@@`\xc0\xc0`\xc0@\xe0\xc0\xc0\xe0\xc0  \x00\xa0 \x00 \xa0\x00\xa0\xa0\x00  \x80\xa0 \x80 \xa0\x80\xa0\xa0\x80` \x00\xe0 \x00`\xa0\x00\xe0\xa0\x00` \x80\xe0 \x80`\xa0\x80\xe0\xa0\x80 `\x00\xa0`\x00 \xe0\x00\xa0\xe0\x00 `\x80\xa0`\x80 \xe0\x80\xa0\xe0\x80``\x00\xe0`\x00`\xe0\x00\xe0\xe0\x00``\x80\xe0`\x80`\xe0\x80\xe0\xe0\x80  @\xa0 @ \xa0@\xa0\xa0@  \xc0\xa0 \xc0 \xa0\xc0\xa0\xa0\xc0` @\xe0 @`\xa0@\xe0\xa0@` \xc0\xe0 \xc0`\xa0\xc0\xe0\xa0\xc0 `@\xa0`@ \xe0@\xa0\xe0@ `\xc0\xa0`\xc0 \xe0\xc0\xa0\xe0\xc0``@\xe0`@`\xe0@\xe0\xe0@``\xc0\xe0`\xc0`\xe0\xc0\xe0\xe0\xc0"
COLOR_MAP = np.frombuffer(DAVIS_PALETTE, dtype=np.uint8).reshape(-1, 3).copy()
# scales for better visualization
COLOR_MAP = (COLOR_MAP.astype(np.float32) * 1.5).clip(0, 255).astype(np.uint8)

def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    return [atoi(c) for c in re.split(r'(\d+)', text)]

def apply_masks_to_images(image_folder, output_path, mask_path):
    images = [img for img in os.listdir(image_folder) if img.endswith((".png", ".jpg", ".jpeg"))]
    images.sort(key=natural_keys)
    masks = [img for img in os.listdir(mask_path) if img.endswith((".png", ".jpg", ".jpeg"))]
    masks.sort(key=natural_keys)

    if not images:
        print("No images found in the specified folder.")
        return
    if not masks:
        print("No masks found in the specified folder.")
        return

    for image_file, mask_file  in zip(images, masks):
        if image_file != mask_file:
            print("Name of Mask and image is not match. Please check.")
            return
        image_path = os.path.join(image_folder, image_file)
        mask_image_path = os.path.join(mask_path, mask_file)
        frame = cv2.imread(image_path)
        mask_frame = cv2.imread(mask_image_path)
        overlay_mask_frame = overlay_davis(frame, mask_frame)
        if not os.path.exists(output_path):
            os.makedirs(output_path)
            print("Made {} dir".format(output_path))
        output_image_path = os.path.join(output_path, mask_file)
        cv2.imwrite(output_image_path, overlay_mask_frame)
        print("Overlay image is saved in {}".format(output_image_path))

def overlay_davis(image: np.ndarray, mask: np.ndarray, alpha: float = 0.5, fade: bool = False):
    """Overlay segmentation on top of RGB image. from davis official"""
    im_overlay = image.copy()

    if len(mask.shape) == 3 and mask.shape[2] == 3:
        # colored_mask = mask
        mask = np.where(mask == 255, 255, 0).astype(np.uint8)
        mask = cv2.cvtColor(mask, cv2.COLOR_BGR2GRAY)
        colored_mask = COLOR_MAP[mask]
    else:
        colored_mask = COLOR_MAP[mask]

    foreground = image * alpha + (1 - alpha) * colored_mask
    binary_mask = mask > 0
    # Compose image
    im_overlay[binary_mask] = foreground[binary_mask]
    if fade:
        im_overlay[~binary_mask] = im_overlay[~binary_mask] * 0.6
    return im_overlay.astype(image.dtype)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Create a video from images in a specified folder.')
    parser.add_argument('--image_folder', '-i', default='/home/kanazawa/Downloads/20240614_tracking_test/20240607_kitchen_bag_10_onion/rgb/', type=str, help='Path to the folder containing images')
    parser.add_argument('--output_path', '-o', default='/home/kanazawa/Downloads/20240614_tracking_test/20240607_kitchen_bag_10_onion/applay_masks', type=str, help='Path to save the output video')
    parser.add_argument('--mask_path', '-m', default='/home/kanazawa/Downloads/20240614_tracking_test/20240607_kitchen_bag_10_onion/output_masks', type=str, help='Path to save the output video')

    args = parser.parse_args()

    apply_masks_to_images(args.image_folder, args.output_path, args.mask_path)

