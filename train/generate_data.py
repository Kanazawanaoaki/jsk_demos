import argparse
import datetime
import logging
from pathlib import Path
import sys

import numpy as np
from pybsc import load_json
from pybsc import makedirs
from pybsc import run_command
from pybsc import touch_gitignore
from tqdm import tqdm

from data import copy_others_to
from generate import create_images
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
    parser.add_argument("--pretrained-model-path", type=str,
                        default="yolov8x-seg.pt")
    parser.add_argument("--compress-annotation-data", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()
    start_time = datetime.datetime.now()

    # Ensure the image directory exists
    image_dir = Path(args.from_images_dir)
    if not image_dir.exists():
        logging.error(f"Image directory {image_dir} does not exist.")
        sys.exit(1)

    outpath_base = Path(args.out).resolve()
    run_command("rm -rf {}".format(outpath_base), shell=True)
    touch_gitignore(outpath_base)

    patterns = ["*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.png", "*.PNG"]
    paths = [p for pattern in patterns for p in image_dir.glob(f"*/{pattern}")]
    target_names = remove_background_and_create_tile_images(
        paths, outpath_base)
    rembg_path = outpath_base / "preprocessing" / "rembg"
    copy_others_to(rembg_path / 'others')
    target_names = sorted(list(set(target_names + ['others'])))
    print(target_names)

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

    label2index = {name: i for i, name in enumerate(target_names)}
    train_path = (outpath_base / "images" / "train").resolve()
    val_path = (outpath_base / "images" / "val").resolve()

    for tgt_path in [train_path, val_path]:
        label_dir = tgt_path.parent.parent / "labels" / tgt_path.name
        makedirs(label_dir)
        paths = list(sorted(tgt_path.glob("*.json")))
        for idx, path in tqdm(enumerate(paths), total=len(paths)):
            data = load_json(path)
            lines = []
            for shapes in data["shapes"]:
                label = shapes["label"].lower()
                if label not in label2index:
                    continue
                index = label2index[label]
                points = shapes["points"]
                width = data["imageWidth"]
                height = data["imageHeight"]
                xy = np.array(list(map(tuple, points)), dtype=np.float64)
                xy[:, 0] /= width
                xy[:, 1] /= height
                lines.append(
                    f'{index} {" ".join(map(str, xy.reshape(-1).tolist()))}')
            with open(label_dir / path.with_suffix(".txt").name, "w") as f:
                f.write("\n".join(lines))

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

    from ultralytics import YOLO

    model = YOLO(args.pretrained_model_path)
    results = model.train(data=config_path, epochs=args.epoch, imgsz=640,
                          batch=args.batch_size,
                          project=str(outpath_base))
