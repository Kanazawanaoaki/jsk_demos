from functools import reduce
import hashlib
from pathlib import Path
import shutil

import gdown
from pybsc import makedirs


download_dir = Path("~/.project_t").expanduser()


def checksum_md5(filename, blocksize=8192):
    """Calculate md5sum.

    Parameters
    ----------
    filename : str or pathlib.Path
        input filename.
    blocksize : int
        MD5 has 128-byte digest blocks (default: 8192 is 128x64).

    Returns
    -------
    md5 : str
        calculated md5sum.
    """
    filename = str(filename)
    hash_factory = hashlib.md5()
    with open(filename, "rb") as f:
        for chunk in iter(lambda: f.read(blocksize), b""):
            hash_factory.update(chunk)
    return hash_factory.hexdigest()


def download_others():
    md5sum = '5ca8983c6e1081b1ed6bc766f9237d42'
    gdrive_id = "19NSQwNnns_pbw8Byz34oztcm-7nzG4Et"
    url = "https://drive.google.com/uc?id={}".format(gdrive_id)
    path = download_dir / "others"
    if path.exists():
        return path
    gdown.cached_download(
        url,
        path=str(download_dir / "others.tar.gz"),
        md5=md5sum,
        postprocess=gdown.extractall,
    )
    return path


def copy_others_to(dst):
    dst = Path(dst)
    makedirs(dst)
    others_path = download_others()
    for path in others_path.glob('*.png'):
        shutil.copy2(path, dst / path.name)


def download_dataset():
    md5sum = "b1d8247eee200dab8ca27633cce376f5"
    gdrive_id = "1n88yJyrsEO59UeRtEhLxBWSQDsN5C-zo"
    url = "https://drive.google.com/uc?id={}".format(gdrive_id)

    project_path = download_dir / "project_t"
    if project_path.exists():
        return project_path
    gdown.cached_download(
        url,
        path=str(download_dir / "project_t.tar.gz"),
        md5=md5sum,
        postprocess=gdown.extractall,
    )
    return project_path


def shi_dataset():
    project_path = download_dataset()
    shi_path = project_path / "2021" / "shi_dataset" / "train"
    json_paths = shi_path.glob("*.json")
    return list(sorted(json_paths))


def t_2021_shelf_dataset(return_img=False):
    project_path = download_dataset()
    data_path = (
        project_path
        / "2022"
        / "thk_eval"
        / "thk_shelf_2022-03-25-13-26-23"
        / "camera--slash--color--slash--image_raw"
    )  # NOQA
    if return_img:
        return list(sorted(data_path.glob("*.png")))
    return list(sorted(data_path.glob("*.json")))


def t_2022_shelf_train_dataset():
    project_path = download_dataset()
    data_path = project_path / "2022" / "shelf_dataset"
    json_paths = data_path.glob("*.json")
    return list(sorted(json_paths))


def t_2022_industrial_dataset(return_img=False, flatten=False):
    scene_names = [
        "hand_camera_for_box_industrial",
        "hand_camera_for_daily_object_sample1",
        "hand_camera_for_daily_object_sample2",
        "r8_realsense_pick_motion_object",
    ]
    project_path = download_dataset()
    if return_img:
        pattern = "*/*.png"
    else:
        pattern = "*/*.json"
    xlst = [
        list(sorted((project_path / "2022" / "thk_eval" / name).glob(pattern)))
        for name in scene_names
    ]
    if flatten:
        return reduce(lambda x, y: x + y, xlst)
    return xlst


def download_items(split="2023-01-16"):
    gdrive_id = "1ZQFMsNO8BuCGgeHdGMNrkhbVkZcRIM0l"
    url = "https://drive.google.com/uc?id={}".format(gdrive_id)

    md5 = "c74656e9b55304182ecd232974f9b147"
    project_path = download_dir / "project_t_items"
    tar_dst_path = download_dir / "project_t_items.tar.gz"
    if tar_dst_path.exists() and checksum_md5(tar_dst_path) == md5:
        return list(sorted(project_path.glob("*/*.png")))
    gdown.cached_download(
        url,
        path=str(download_dir / "project_t_items.tar.gz"),
        postprocess=gdown.extractall,
        md5=md5,
    )
    return list(sorted(project_path.glob("*/*.png")))


def download_bg_dataset():
    gdrive_id = "1N0SEwYo_GxFBFz_HXQzZQ4S1MjNASMhu"
    url = "https://drive.google.com/uc?id={}".format(gdrive_id)

    project_path = download_dir / "bg-20k"
    if project_path.exists():
        return project_path
    gdown.cached_download(
        url,
        path=str(download_dir / "bg-20k.tar.gz"),
        postprocess=gdown.extractall,
    )
    return project_path


if __name__ == "__main__":
    download_bg_dataset()
    download_others()
