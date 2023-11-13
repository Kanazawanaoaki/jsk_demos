import logging
from math import atan2
from math import cos
from math import pi
from math import sin
from math import sqrt
import multiprocessing
from pathlib import Path
from typing import List

import cv2
import numpy as np
from pybsc.image_utils import add_alpha_channel
from pybsc.image_utils import apply_mask
from pybsc.image_utils import create_tile_image
from pybsc.image_utils import imread
from pybsc.image_utils import resize_keeping_aspect_ratio_wrt_longside
from pybsc.image_utils import rotate
from pybsc import makedirs
from pybsc.parallel import parallel_tqdm
from rembg import remove
from rembg.sessions.u2net import U2netSession
from skimage import measure


def rembg_worker(queue, pbar):
    while True:
        (
            image_path,
            rembg_outpath,
            rembg_org_img_outpath,
            img_and_rembg_outpath,
        ) = queue.get()
        if image_path is None:
            queue.task_done()
            break
        process_images(
            image_path, rembg_outpath,
            rembg_org_img_outpath, img_and_rembg_outpath
        )
        queue.task_done()
        pbar.update()


def parallel_remove_background(paths: List[Path], outpath_base: Path):
    U2netSession.download_models()
    outpath_base = Path(outpath_base)
    rembg_outpath = outpath_base / "preprocessing" / "rembg"
    rembg_org_img_outpath = outpath_base / "preprocessing" / "rembg_org"
    img_and_rembg_outpath = outpath_base / "preprocessing" / "img_and_rembg"

    file_queue = multiprocessing.JoinableQueue()
    jobs = multiprocessing.cpu_count()
    with parallel_tqdm(total=len(paths)) as pbar:
        procs = []
        for _ in range(jobs):
            proc = multiprocessing.Process(
                target=rembg_worker,
                args=(
                    file_queue,
                    pbar,
                ),
            )
            proc.start()
            procs.append(proc)
        for i, path in enumerate(paths):
            file_queue.put(
                (
                    str(path),
                    str(rembg_outpath),
                    str(rembg_org_img_outpath),
                    str(img_and_rembg_outpath),
                )
            )
        for _ in range(jobs):
            file_queue.put((None, None, None, None))
        file_queue.join()
    pbar.close()


def remove_background_and_create_tile_images(paths, outpath_base):
    rembg_outpath = outpath_base / "preprocessing" / "rembg"
    rembg_org_img_outpath = outpath_base / "preprocessing" / "rembg_org"
    tile_image_outpath = outpath_base / "preprocessing" / "tile_rembg"

    logging.info("Removing background from images")
    parallel_remove_background(paths, outpath_base)

    target_names = [
        dir.name
        for dir in rembg_org_img_outpath.iterdir() if dir.is_dir()]
    target_names = sorted(list(set(target_names)))

    makedirs(tile_image_outpath)
    logging.info("Creating tile images")
    for target_name in target_names:
        tile_img = create_tile_image(
            list((rembg_outpath / target_name).glob("*.png")),
            num_tiles_per_row=5
        )
        tile_img.save(tile_image_outpath / f"{target_name}.png")

    tile_org_and_rembg_outpath = outpath_base \
        / "preprocessing" / "tile_org_and_rembg"
    target_names = [
        dir.name for dir in (rembg_org_img_outpath.iterdir()) if dir.is_dir()
    ]
    target_names = sorted(list(set(target_names)))

    makedirs(tile_org_and_rembg_outpath)
    for target_name in target_names:
        tile_org_and_rembg_img_paths = []
        for a in (rembg_outpath / target_name).glob("*.png"):
            tile_org_and_rembg_img_paths.append(
                rembg_org_img_outpath
                / target_name / a.with_suffix(".jpg").name
            )
            tile_org_and_rembg_img_paths.append(a)
        tile_img = create_tile_image(
            tile_org_and_rembg_img_paths, num_tiles_per_row=6)
        tile_img.save(
            tile_org_and_rembg_outpath / "{}.png".format(target_name))
    return target_names


def draw_axis(img, p_, q_, colour, scale):
    p = list(p_)
    q = list(q_)

    angle = atan2(p[1] - q[1], p[0] - q[0])  # angle in radians
    hypotenuse = sqrt((p[1] - q[1]) * (p[1] - q[1])
                      + (p[0] - q[0]) * (p[0] - q[0]))
    # Here we lengthen the arrow by a factor of scale
    q[0] = p[0] - scale * hypotenuse * cos(angle)
    q[1] = p[1] - scale * hypotenuse * sin(angle)
    cv2.line(
        img, (int(p[0]), int(p[1])), (int(q[0]), int(q[1])),
        colour, 1, cv2.LINE_AA
    )
    # create the arrow hooks
    p[0] = q[0] + 9 * cos(angle + pi / 4)
    p[1] = q[1] + 9 * sin(angle + pi / 4)
    cv2.line(
        img, (int(p[0]), int(p[1])), (int(q[0]), int(q[1])),
        colour, 1, cv2.LINE_AA
    )
    p[0] = q[0] + 9 * cos(angle - pi / 4)
    p[1] = q[1] + 9 * sin(angle - pi / 4)
    cv2.line(
        img, (int(p[0]), int(p[1])), (int(q[0]), int(q[1])),
        colour, 1, cv2.LINE_AA
    )


def get_orientation(pts, img):
    sz = len(pts)
    data_pts = np.empty((sz, 2), dtype=np.float64)
    for i in range(data_pts.shape[0]):
        data_pts[i, 0] = pts[i, 0, 0]
        data_pts[i, 1] = pts[i, 0, 1]
    # Perform PCA analysis
    mean = np.empty((0))
    mean, eigenvectors, eigenvalues = cv2.PCACompute2(data_pts, mean)
    # Store the center of the object
    cntr = (int(mean[0, 0]), int(mean[0, 1]))
    # cv2.circle(img, cntr, 3, (255, 0, 255), 2)
    p1 = (
        cntr[0] + 0.02 * eigenvectors[0, 0] * eigenvalues[0, 0],
        cntr[1] + 0.02 * eigenvectors[0, 1] * eigenvalues[0, 0],
    )
    p2 = (
        cntr[0] - 0.02 * eigenvectors[1, 0] * eigenvalues[1, 0],
        cntr[1] - 0.02 * eigenvectors[1, 1] * eigenvalues[1, 0],
    )
    draw_axis(img, cntr, p1, (0, 255, 0), 1)
    draw_axis(img, cntr, p2, (255, 255, 0), 5)
    angle = atan2(eigenvectors[0, 1], eigenvectors[0, 0])
    return angle


def remove_background(
        img, path_name=None, return_info=False,
        kernel_size=5, iterations=4, debug=False
):
    if debug is True:
        from pathlib import Path

        from pybsc.image_utils import apply_mask
        from pybsc import make_fancy_output_dir

        output_path = Path(
            make_fancy_output_dir("./remove_bg_debug", no_save=True))
        debug_prefix = 1

    img = remove(img)

    if debug is True:
        cv2.imwrite(
            str(output_path / "{}-remove-bg.png".format(debug_prefix)), img)
        debug_prefix += 1

    kernel = np.ones((kernel_size, kernel_size))
    mask = 255 * np.array(img[..., 3] > 0, dtype=np.uint8)
    img_dil = cv2.erode(mask, kernel, iterations=iterations)

    if debug is True:
        cv2.imwrite(
            str(output_path / "{}-erode.png".format(debug_prefix)),
            apply_mask(img, img_dil),
        )
        debug_prefix += 1

    img_opening = cv2.dilate(img_dil, kernel, iterations=iterations)

    if debug is True:
        cv2.imwrite(
            str(output_path / "{}-dilate.png".format(debug_prefix)),
            apply_mask(img, img_opening),
        )
        debug_prefix += 1

    labels = measure.label(img_opening, background=0)
    mask_area = [np.sum(labels == i) for i in range(1, np.max(labels) + 1)]
    largest_mask_label = np.argmax(mask_area) + 1
    final_mask = (labels == largest_mask_label).astype(np.uint8) * 255
    y, x = np.where(final_mask > 0)

    x1 = np.min(x)
    x2 = np.max(x)
    y1 = np.min(y)
    y2 = np.max(y)
    img = img[y1:y2, x1:x2]

    mask_copy = (img[..., 3] > 0).copy()
    mask_copy = 255 * np.array(mask_copy, dtype=np.uint8)

    contours, _ = cv2.findContours(
        mask_copy, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)

    areas = [cv2.contourArea(c) for i, c in enumerate(contours)]
    contour = contours[np.argmax(areas)]
    hoge_img = img.copy()[..., :3]

    rect = cv2.minAreaRect(contour)
    box = cv2.boxPoints(rect)
    box = np.int0(box)

    hoge_img = np.array(hoge_img, dtype=np.uint8)
    hoge_img = cv2.drawContours(
        hoge_img, contours, int(np.argmax(areas)), (0, 0, 255), 3
    )
    angle = get_orientation(contour, hoge_img)
    angle = get_orientation(box.reshape(-1, 1, 2), hoge_img)
    angle = np.rad2deg(angle)
    img = rotate(img, angle=angle)
    if debug is True:
        cv2.imwrite(
            str(output_path / "{}-rotated.png".format(debug_prefix)), img)
        debug_prefix += 1
    if return_info:
        return img, (x1, y1, x2, y2), angle, mask
    return img


def process_images(
    image_path, rembg_outpath, rembg_org_img_outpath, img_and_rembg_outpath,
    max_img_size=1280
):
    image_path = Path(image_path)
    rembg_outpath = Path(rembg_outpath)
    rembg_org_img_outpath = Path(rembg_org_img_outpath)
    img_and_rembg_outpath = Path(img_and_rembg_outpath)
    try:
        # Create necessary directories
        makedirs(rembg_outpath / image_path.parent.name, exist_ok=True)
        makedirs(rembg_org_img_outpath / image_path.parent.name, exist_ok=True)
        makedirs(img_and_rembg_outpath / image_path.parent.name, exist_ok=True)

        # Read the original image
        org_img = imread(str(image_path), color_type="bgr", clear_alpha=True)
        if org_img.shape[0] > max_img_size or org_img.shape[1] > max_img_size:
            org_img = resize_keeping_aspect_ratio_wrt_longside(
                org_img, max_img_size)

        # Remove background
        out_img, (x1, y1, x2, y2), angle, mask = remove_background(
            org_img.copy(), return_info=True
        )

        # Save the image with removed background
        cv2.imwrite(
            str(
                rembg_outpath
                / image_path.parent.name
                / image_path.with_suffix(".png").name
            ),
            out_img,
        )

        # Save the rotated image
        cv2.imwrite(
            str(
                rembg_org_img_outpath
                / image_path.parent.name
                / image_path.with_suffix(".jpg").name
            ),
            rotate(org_img[y1:y2, x1:x2], angle=angle),
        )

        # Process and concatenate images
        rembg_org_size_img = apply_mask(org_img.copy(), mask, use_alpha=True)
        if org_img.shape[2] == 3:
            concatenated_images = np.concatenate(
                (add_alpha_channel(
                    org_img, alpha=255), rembg_org_size_img), axis=1
            )
        else:
            concatenated_images = np.concatenate(
                (org_img, rembg_org_size_img), axis=1)

        # Save concatenated image
        cv2.imwrite(
            str(
                img_and_rembg_outpath
                / image_path.parent.name
                / image_path.with_suffix(".png").name
            ),
            concatenated_images,
        )

        return True
    except Exception as e:
        print(str(e))
        return False


if __name__ == "__main__":
    import argparse
    from pathlib import Path

    from pybsc import make_fancy_output_dir

    parser = argparse.ArgumentParser(description="remove bg")
    parser.add_argument("targetpath", type=str)
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()

    outpath = Path(make_fancy_output_dir("./rembg_img", no_save=True))
    paths = (
        list(sorted(Path(args.targetpath).glob("*/*.jpg")))
        + list(sorted(Path(args.targetpath).glob("*/*.jpeg")))
        + list(sorted(Path(args.targetpath).glob("*/*.png")))
    )
    for path in paths:
        print(path.name)
        try:
            makedirs(outpath / path.parent.name)
            out_img = remove_background(
                cv2.imread(str(path)), debug=args.debug)

            cv2.imwrite(
                str(outpath
                    / path.parent.name
                    / path.with_suffix(".png").name), out_img
            )
        except Exception as e:
            print(str(e))
