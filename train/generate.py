import argparse
from collections import defaultdict
import copy
import multiprocessing
import os
from pathlib import Path

import numpy as np
from PIL import Image
from pybsc import make_fancy_output_dir
from pybsc import makedirs
from pybsc.parallel import parallel_tqdm

from aug import random_binpacking
from aug import random_crop_with_size
from data import download_bg_dataset
from labelme_utils import create_instance_mask_json


def generate_data_worker(
        queue, img_paths, pbar, targets,
        image_width, max_angle, min_scale, max_scale
):
    np.random.seed(os.getpid())
    img_probs = np.zeros(len(img_paths))
    img_paths = [Path(path) for path in img_paths]
    cnt_dict = defaultdict(int)
    for i, ip in enumerate(img_paths):
        obj_name = ip.parent.name.lower()
        if obj_name not in targets:
            cnt_dict["others"] += 1
        else:
            cnt_dict[obj_name] += 1
    if cnt_dict["others"] == 0:
        others_p = 0.0
        p = 1.0
        p_per_class = p / (len(cnt_dict) - 1)
    else:
        p = 0.9
        others_p = (1 - p) / cnt_dict["others"]
        p_per_class = p / (len(cnt_dict) - 1)

    for i, ip in enumerate(img_paths):
        obj_name = ip.parent.name.lower()
        if obj_name == "others" or obj_name not in targets:
            img_probs[i] = others_p
        else:
            img_probs[i] = p_per_class / cnt_dict[obj_name]

    bg_paths = list((Path(download_bg_dataset()) / "train").glob("*.jpg"))

    acc_cnt = defaultdict(int)
    for i, ip in enumerate(img_paths):
        obj_name = ip.parent.name.lower()
        if obj_name == "others" or obj_name not in targets:
            acc_cnt["others"] = 0
        else:
            acc_cnt[obj_name] = 0

    class_names = sorted(list(cnt_dict.keys()))

    while True:
        output_img_path = queue.get()
        if output_img_path is None:
            queue.task_done()
            break

        bg_path = np.random.choice(bg_paths)
        pil_bg_img = Image.open(bg_path)
        bg_img = random_crop_with_size(pil_bg_img, image_width=image_width)
        gen_img, bboxes, names, instance_mask = random_binpacking(
            bg_img,
            img_paths,
            p=img_probs,
            targets=targets,
            image_width=image_width,
            max_angle=max_angle,
            min_scale=min_scale,
            max_scale=max_scale,
            cnt_dict=copy.deepcopy(cnt_dict),
            acc_cnt=copy.deepcopy(acc_cnt),
        )
        for name in names:
            acc_cnt[name] += 1
        max_value = max(acc_cnt.values())
        probs = []
        new_names = []
        for key, value in acc_cnt.items():
            probs.append((max_value - value) ** 2)
            new_names.append(key)
        probs = np.array(probs)
        if probs.sum() != 0.0:
            probs = probs / probs.sum()
        else:
            probs = 1 / len(probs) * np.ones(len(probs))
        name2prob = {nn: float(prob) for nn, prob in zip(new_names, probs)}

        for idx, ip in enumerate(img_paths):
            obj_name = ip.parent.name.lower()
            if obj_name == "others" or obj_name not in targets:
                img_probs[idx] = name2prob["others"] / cnt_dict["others"]
            else:
                img_probs[idx] = name2prob[obj_name] / cnt_dict[obj_name]

        create_instance_mask_json(
            output_img_path, gen_img, instance_mask, names, class_names
        )
        queue.task_done()
        pbar.update()


def create_images(
    target_image_dir,
    output_path,
    target_names,
    n=20000,
    jobs=None,
    val_size=0.2,
    image_width=640,
    max_angle=360,
    min_scale=0.1,
    max_scale=0.5,
):
    if jobs is None or jobs == -1:
        jobs = multiprocessing.cpu_count()

    output_path = Path(output_path)
    train_path = output_path / "train"
    val_path = output_path / "val"
    makedirs(train_path)
    makedirs(val_path)
    target_names = [tgt.lower() for tgt in target_names]

    print(target_image_dir)
    img_paths = list(sorted(Path(target_image_dir).glob("*/*.png")))
    img_paths = [str(path) for path in img_paths]
    download_bg_dataset()

    file_queue = multiprocessing.JoinableQueue()
    jobs = multiprocessing.cpu_count()
    val_size = int(n * val_size)
    with parallel_tqdm(total=n) as pbar:
        procs = []
        for _ in range(jobs):
            proc = multiprocessing.Process(
                target=generate_data_worker,
                args=(
                    file_queue,
                    img_paths,
                    pbar,
                    target_names,
                    image_width,
                    max_angle,
                    min_scale,
                    max_scale,
                ),
            )
            proc.start()
            procs.append(proc)
        for i in range(n - val_size):
            file_queue.put(str(train_path / "{0:08}.jpg".format(i)))
        for i in range(val_size):
            file_queue.put(str(val_path / "{0:08}.jpg".format(i)))
        for _ in range(jobs):
            file_queue.put(None)
        file_queue.join()
    pbar.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="data generator")
    parser.add_argument("-n", default=1000, type=int)
    parser.add_argument("-o", "--out", default="./gen_data", type=str)
    parser.add_argument("--image-width", default=300, type=int)
    parser.add_argument("-j", "--jobs", default=4, type=int)
    parser.add_argument("--min-scale", default=0.1)
    parser.add_argument("--max-scale", default=0.5)
    parser.add_argument("--target-image-dir", type=str)
    parser.add_argument("-t", "--target-names", nargs="+")
    args = parser.parse_args()

    output_path = make_fancy_output_dir(args.out)
    create_images(
        args.target_image_dir,
        output_path,
        args.target_names,
        n=args.n,
        jobs=args.jobs,
        min_scale=args.min_scale,
        max_scale=args.max_scale,
    )
