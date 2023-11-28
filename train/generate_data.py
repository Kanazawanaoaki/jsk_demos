import argparse
import datetime
import logging
from pathlib import Path
import sys

import cv2
from pybsc import makedirs
from pybsc import run_command
from pybsc import touch_gitignore

from data import copy_others_to
from generate import create_images
from labelme_utils import parallel_labelme_to_yolo
from remove_bg import remove_background_and_create_tile_images


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Data generator")
    parser.add_argument("-n", default=1000, type=int)
    parser.add_argument("-b", '--batch-size', default=-1, type=int)
    parser.add_argument("--image-width", default=640, type=int)
    parser.add_argument("--epoch", default=10, type=int)
    parser.add_argument("--target", default="fruit", type=str)
    parser.add_argument("-t", "--target-names", nargs="+")
    parser.add_argument("-o", "--out", default="./gen_data", type=str)
    parser.add_argument("--no-train", action="store_true")
    parser.add_argument("-j", "--jobs", default=-1, type=int)
    parser.add_argument("--min-scale", default=0.2, type=float)
    parser.add_argument("--max-scale", default=0.6, type=float)
    parser.add_argument("--target-image-dir", type=str)
    parser.add_argument("--from-images-dir", type=str, default="")
    parser.add_argument("--video-path", type=str, default="")
    parser.add_argument("--pretrained-model-path", type=str,
                        default="yolov8x-seg.pt")
    parser.add_argument("--compress-annotation-data", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()
    start = datetime.datetime.now()

    # Ensure the image directory exists
    image_dir = Path(args.from_images_dir)
    if not image_dir.exists():
        logging.error(f"Image directory {image_dir} does not exist.")
        sys.exit(1)

    outpath_base = Path(args.out).resolve()
    makedirs(outpath_base)
    touch_gitignore(outpath_base)

    patterns = ["*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.png", "*.PNG"]
    paths = [p for pattern in patterns for p in image_dir.glob(f"*/{pattern}")]
    target_names = remove_background_and_create_tile_images(
        paths, outpath_base,
        preprocess_only=True)
    end = datetime.datetime.now()
    print(end - start)

    rembg_path = outpath_base / "preprocessing" / "rembg"
    copy_others_to(rembg_path / 'others')
    target_names = sorted(list(set(target_names + ['others'])))
    print(target_names)

    # remove labels and images
    run_command(f'rm -rf {outpath_base / "images"}', shell=True)
    run_command(f'rm -rf {outpath_base / "labels"}', shell=True)
    end = datetime.datetime.now()
    print(end - start)

    makedirs(args.out)
    create_images(
        rembg_path,
        outpath_base / "images",
        target_names,
        n=args.n,
        jobs=args.jobs,
        image_width=args.image_width,
        min_scale=args.min_scale,
        max_scale=args.max_scale,
    )
    end = datetime.datetime.now()
    print(end - start)

    label2index = {name: i for i, name in enumerate(target_names)}
    train_path = (outpath_base / "images" / "train").resolve()
    val_path = (outpath_base / "images" / "val").resolve()

    for tgt_path in [train_path, val_path]:
        parallel_labelme_to_yolo(tgt_path, label2index)

    end = datetime.datetime.now()
    print(end - start)

    yolo_yaml_data = {
        "path": f"{outpath_base}",
        "train": f"{train_path}",
        "val": f"{val_path}",
        "test": "",
        "nc": len(target_names),
        "names": {i: name for i, name in enumerate(target_names)},
        "mosaic": 0.8,  # image mosaic (probability)
        "mixup": 0.4,  # image mixup (probability)
    }

    import yaml

    config_path = outpath_base / "config.yaml"
    with open(config_path, "w") as f:
        f.write(yaml.dump(yolo_yaml_data))

    from ultralytics.utils import SETTINGS
    from ultralytics import YOLO
    SETTINGS['wandb'] = False
    run_command(f'rm -rf {outpath_base / "train*"}', shell=True)
    model = YOLO(args.pretrained_model_path)
    results = model.train(data=config_path, epochs=args.epoch, imgsz=640,
                          batch=args.batch_size,
                          project=str(outpath_base),
                          save_period=-1,
                          save=False)
    end = datetime.datetime.now()
    print(end - start)

    if len(args.video_path) > 0:
        video_path = args.video_path
        output_video_path = outpath_base / Path(video_path).name
        cap = cv2.VideoCapture(video_path)
        codec = cv2.VideoWriter_fourcc(*'mp4v')
        fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
        video = None
        while cap.isOpened():
            success, frame = cap.read()
            if success:
                if video is None:
                    print(f'Saved to {str(output_video_path)}')
                    video = cv2.VideoWriter(
                        str(output_video_path), fourcc,
                        30.0, (frame.shape[1], frame.shape[0]))
                results = model(frame)
                annotated_frame = results[0].plot()
                video.write(annotated_frame)
            else:
                break
        cap.release()
        video.release()
        print(f'Saved to {str(output_video_path)}')
