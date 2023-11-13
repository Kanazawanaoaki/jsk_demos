import collections
from collections import defaultdict
import glob
import json
import os
import os.path as osp
from pathlib import Path
import shutil
import subprocess
from typing import Dict
from typing import List

import funcy
import imantics
import imgviz
from joblib import delayed
from joblib import Parallel
import labelme
import numpy as np
from PIL import Image
from pybsc import load_json
from pybsc import makedirs
from pybsc import save_json
from sklearn.model_selection import train_test_split
from tqdm import tqdm


def polygons_to_area(polygons):
    x = polygons[:, 0]
    y = polygons[:, 1]
    return 0.5 * np.abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))


def polygons_to_bbox(polygons, order="yxyx"):
    xy = np.array(list(map(tuple, polygons)))
    y_min = xy[:, 1].min()
    x_min = xy[:, 0].min()
    y_max = xy[:, 1].max() + 1
    x_max = xy[:, 0].max() + 1
    if order in ["yxyx", "yx"]:
        bbox = np.array([y_min, x_min, y_max, x_max],
                        dtype=np.float32)
    elif order == "yxwh":
        bbox = np.array([y_min, x_min, y_max - y_min, x_max - x_min],
                        dtype=np.float32)
    elif order in ["xyxy", "xy"]:
        bbox = np.array([x_min, y_min, x_max, y_max], dtype=np.float32)
    elif order == "xywh":
        bbox = np.array([x_min, y_min, x_max - x_min, y_max - y_min],
                        dtype=np.float32)
    elif order == "yolo":
        width = x_max - x_min
        height = y_max - y_min
        cx = x_min + width / 2.0
        cy = y_min + height / 2.0
        bbox = np.array([cx, cy, width, height], dtype=np.float32)
    else:
        raise NotImplementedError
    return bbox


def filter_annotations(annotations: List[Dict], images: List[Dict]):
    image_ids = []
    for i in tqdm(images):
        image_ids.append(int(i["id"]))
    image_ids = frozenset(image_ids)
    ret = []
    for ann in tqdm(annotations):
        if int(ann["image_id"]) in image_ids:
            ret.append(ann)
    return ret


def coco_split(
    coco_json_path,
    train_json_path,
    test_json_path,
    train_size=0.8,
    ignore_image_without_annotation=False,
    thinout_number=None,
):
    if isinstance(coco_json_path, dict):
        coco_data = coco_json_path
    else:
        coco_data = load_json(coco_json_path)

    images = coco_data["images"]
    annotations = coco_data["annotations"]
    categories = coco_data["categories"]

    if ignore_image_without_annotation:
        images_with_annotations = funcy.lmap(
            lambda a: int(a["image_id"]), annotations)
        images = funcy.lremove(
            lambda i: i["id"] not in images_with_annotations, images)

    if thinout_number is not None:
        np.random.shuffle(images)
        images = images[:thinout_number]
    x, y = train_test_split(images, train_size=train_size)

    train = {
        "images": x,
        "annotations": filter_annotations(annotations, x),
        "categories": categories,
    }
    test = {
        "images": y,
        "annotations": filter_annotations(annotations, y),
        "categories": categories,
    }

    makedirs(Path(train_json_path).parent)
    makedirs(Path(test_json_path).parent)
    save_json(train, train_json_path, backend="orjson")
    save_json(test, test_json_path, backend="orjson")


def get_annotation(points, label, num):
    annotation = {}
    contour = np.array(points)
    x = contour[:, 0]
    y = contour[:, 1]
    area = 0.5 * np.abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))
    annotation["segmentation"] = tuple(
        [tuple(map(float, np.asarray(points).flatten()))]
    )
    annotation["iscrowd"] = 0
    annotation["area"] = float(area)
    annotation["image_id"] = int(num)

    annotation["bbox"] = list(
        map(float, polygons_to_bbox(points, order="xywh")))

    annotation["category_id"] = label[0]
    return annotation


def get_image_info(json_filepath, data, num, out_dir):
    image = {}
    img_path = osp.join(osp.dirname(json_filepath), data["imagePath"])
    if not osp.exists(img_path):
        return None
    # img = utils.img_b64_to_arr(data["imageData"])
    # height, width = img.shape[:2]
    # img = None
    # height, width = img.shape[:2]
    width, height = Image.open(img_path).size
    image["height"] = height
    image["width"] = width
    image["id"] = num
    file_name = "{0:08}{1}".format(num, osp.splitext(img_path)[1])
    shutil.copy(img_path, osp.join(out_dir, file_name))
    tmp_json_data = load_json(json_filepath)
    tmp_json_data["imagePath"] = file_name
    save_json(tmp_json_data,
              osp.join(out_dir, osp.splitext(file_name)[0] + ".json"))
    image["file_name"] = file_name.split("/")[-1]
    return image


def _extract_info_from_json(json_filepath, num, out_dir):
    data = load_json(json_filepath, backend="orjson")
    elem_image = get_image_info(json_filepath, data, num, out_dir)
    if elem_image is None:
        return {}, [], []
    elem_annotations = []
    labels = []
    for shapes in data["shapes"]:
        label = shapes["label"].split("_")
        if label not in labels:
            labels.append(label)
        points = shapes["points"]
        elem_annotations.append(get_annotation(points, label, num))
    return elem_image, elem_annotations, labels


class Labelme2Coco(object):
    def __init__(
        self,
        labelme_json,
        save_train_json_path,
        save_val_json_path=None,
        split_train_val=False,
        n_jobs=-1,
    ):
        if split_train_val is True and save_val_json_path is None:
            raise ValueError("You must give save_val_json_path.")
        self.labelme_json = labelme_json
        self.split_train_val = split_train_val
        self.save_train_json_path = save_train_json_path
        self.save_val_json_path = save_val_json_path
        self.images = []
        self.categories = []
        self.annotations = []
        self.label = []
        self.annID = 1
        self.n_jobs = n_jobs

        self.data_transfer()
        self.save_json()

    def data_transfer(self):
        save_train_json_path = self.save_train_json_path
        makedirs(Path(save_train_json_path).parent / "images")
        results = Parallel(n_jobs=self.n_jobs)(
            delayed(_extract_info_from_json)(
                json_filepath, i,
                str(Path(save_train_json_path).parent / "images")
            )
            for i, json_filepath in tqdm(
                enumerate(self.labelme_json), total=len(self.labelme_json)
            )
        )

        for elem_images, elem_annotations, labels in results:
            for label in labels:
                if label not in self.label:
                    self.label.append(label)
            self.images.append(elem_images)
            for elem_anno in elem_annotations:
                elem_anno["id"] = self.annID
                self.annID += 1
                self.annotations.append(elem_anno)

        # Sort all text labels
        # so they are in the same order across data splits.
        self.label.sort()
        for label in self.label:
            self.categories.append(self.category(label))
        for annotation in self.annotations:
            annotation["category_id"] = self.getcatid(
                annotation["category_id"])

    def category(self, label):
        category = {}
        category["supercategory"] = label[0]
        category["id"] = len(self.categories)
        category["name"] = label[0]
        return category

    def getcatid(self, label):
        for category in self.categories:
            if label == category["name"]:
                return int(category["id"])
        raise RuntimeError(
            "label: {} not in categories: {}.".format(label, self.categories)
        )

    def save_json(self):
        data_coco = {}
        data_coco["images"] = self.images
        data_coco["categories"] = self.categories
        data_coco["annotations"] = self.annotations

        makedirs(osp.dirname(osp.abspath(self.save_train_json_path)))
        if self.split_train_val is True:
            makedirs(osp.dirname(osp.abspath(self.save_val_json_path)))
            coco_split(
                data_coco,
                self.save_train_json_path,
                self.save_val_json_path,
                train_size=0.8,
            )
        else:
            save_json(data_coco, self.save_train_json_path, backend="orjson")


def labelme2coco(
    labelme_jsons,
    save_train_json_path,
    save_val_json_path=None,
    split_train_val=False,
    n_jobs=-1,
):
    Labelme2Coco(
        labelme_jsons, save_train_json_path,
        save_val_json_path, split_train_val, n_jobs
    )


def box2labelme(img, bboxes, label_names):
    H, W, _ = img.shape
    data = {}
    data["flags"] = {}
    data["imageHeight"] = H
    data["imageWidth"] = W
    data["shapes"] = []
    data["version"] = "4.1.2"
    data["imageData"] = None

    for group_id, (label_name, bbox) in enumerate(zip(label_names, bboxes)):
        y1, x1, y2, x2 = bbox
        rect = {}
        rect["flags"] = {}
        rect["group_id"] = None
        rect["label"] = label_name
        rect["points"] = [[float(x1), float(y1)], [float(x2), float(y2)]]
        rect["shape_type"] = "rectangle"
        data["shapes"].append(rect)
    return data


def label2instance_boxes(label_instance, label_class, return_masks=False):
    """Convert instance label to boxes.

    Parameters
    ----------
    label_instance: numpy.ndarray, (H, W)
        Label image for instance id.
    label_class: numpy.ndarray, (H, W)
        Label image for class.
    return_masks: bool
        Flag to return each instance mask.

    Returns
    -------
    instance_classes: numpy.ndarray, (n_instance,)
        Class id for each instance.
    boxes: (n_instance, 4)
        Bounding boxes for each instance. (x1, y1, x2, y2)
    instance_masks: numpy.ndarray, (n_instance, H, W), bool
        Masks for each instance. Only returns when return_masks=True.
    """
    instances = np.unique(label_instance)
    instances = instances[instances != -1]
    n_instance = len(instances)
    # instance_class is 'Class of the Instance'
    instance_classes = np.zeros((n_instance,), dtype=np.int32)
    boxes = np.zeros((n_instance, 4), dtype=np.int32)
    H, W = label_instance.shape
    instance_masks = np.zeros((n_instance, H, W), dtype=bool)
    for i, inst in enumerate(instances):
        mask_inst = label_instance == inst
        count = collections.Counter(label_class[mask_inst].tolist())
        instance_class = max(count.items(), key=lambda x: x[1])[0]

        assert inst not in [-1]
        # assert instance_class not in [-1, 0]

        where = np.argwhere(mask_inst)
        (y1, x1), (y2, x2) = where.min(0), where.max(0) + 1

        instance_classes[i] = instance_class
        boxes[i] = (y1, x1, y2, x2)
        instance_masks[i] = mask_inst
    if return_masks:
        return instance_classes, boxes, instance_masks
    else:
        return instance_classes, boxes


def mask2labelme(
    mask, instance_mask, label_names=None, mask_to_bbox=False, min_area=30
):
    if label_names is not None:
        label_id_to_classname = {}
        for label_id, label_name in enumerate(label_names):
            label_id_to_classname[label_id] = label_name

    instance_mask = np.array(instance_mask, dtype=np.int32)
    H, W = mask.shape
    data = {}
    data["flags"] = {}
    data["imageHeight"] = H
    data["imageWidth"] = W
    data["shapes"] = []
    data["version"] = "4.1.2"
    data["imageData"] = None

    instance_mask[instance_mask == 0] = -1  # instance id 0 should be ignored.

    labels, bboxes, masks = label2instance_boxes(
        label_instance=instance_mask,
        label_class=mask,
        return_masks=True,
    )
    group_id = 0
    for class_index, bbox, mask in zip(labels, bboxes, masks):
        if mask_to_bbox:
            y1, x1, y2, x2 = bbox
            if min_area is not None and abs(y2 - y1) * abs(x2 - x1) < min_area:
                continue
            rect = {}
            rect["flags"] = {}
            rect["group_id"] = None
            if label_names is not None:
                rect["label"] = label_id_to_classname[class_index]
            else:
                rect["label"] = str(int(class_index))
            rect["points"] = [[float(x1), float(y1)], [float(x2), float(y2)]]
            rect["shape_type"] = "rectangle"
            data["shapes"].append(rect)
        else:
            polygons = imantics.Mask(mask).polygons()
            for point in polygons.points:
                if len(point) <= 2:
                    continue
                area = polygons_to_area(point)
                if min_area is not None and area < min_area:
                    continue
                poly = {}
                poly["flags"] = {}
                poly["group_id"] = group_id
                if label_names is not None:
                    poly["label"] = label_id_to_classname[class_index]
                poly["points"] = point.tolist()
                poly["shape_type"] = "polygon"
                data["shapes"].append(poly)
        group_id += 1
    return data


def create_mask_from_instance_mask(
        instance_mask, class_names, whole_class_names):
    ids = [whole_class_names.index(cl) for cl in class_names]
    mask = np.zeros(instance_mask.shape, dtype=np.int32)
    for instance_id, class_id in zip(range(1, instance_mask.max() + 1), ids):
        mask[instance_mask == instance_id] = np.int32(class_id)
    return mask


def create_json(filename, img, bboxes, names):
    img.save(str(filename))
    json_path = Path(filename).with_suffix(".json")
    filename = Path(filename).name
    data = box2labelme(np.array(img), bboxes, names)
    data["imagePath"] = Path(filename).name
    save_json(data, json_path)


def create_instance_mask_json(
        filename, img, instance_mask, names, class_names):
    instance_mask = np.array(instance_mask, dtype=np.int64)
    img.save(str(filename))
    json_path = Path(filename).with_suffix(".json")
    filename = Path(filename).name
    class_mask = create_mask_from_instance_mask(
        instance_mask, names, class_names)
    data = mask2labelme(
        class_mask, instance_mask, label_names=class_names, mask_to_bbox=False
    )
    data["imagePath"] = Path(filename).name
    save_json(data, json_path)


def get_class_names_from_labelme_jsons(jsons, name_converter_dict=None):
    class_names = []
    for path in jsons:
        data = load_json(path)
        if len(data["shapes"]) > 0:
            class_names.extend(
                [shape["label"].lower() for shape in data["shapes"]])
    class_names = list(set(class_names))
    if name_converter_dict is not None:
        new_class_names = []
        for n in class_names:
            if n in name_converter_dict:
                n = name_converter_dict[n]
            new_class_names.append(n)
        class_names = new_class_names
    return sorted(list(set(class_names)))


def agg_data(root_path, dst_path):
    jsons = sorted(list(Path(root_path).glob("*/*/*.json")))
    dst_path = Path(dst_path)
    makedirs(dst_path)
    img_idx = 0
    for json_path in jsons:
        data = load_json(json_path)
        img_path = json_path.parent / data["imagePath"]
        new_img_path = dst_path / "{0:08}{1}".format(img_idx, img_path.suffix)
        data["imagePath"] = new_img_path.name
        img_idx += 1
        shutil.copy(str(img_path), str(new_img_path))
        save_json(data, str(new_img_path.with_suffix(".json")))


def min_index(arr1, arr2):
    """Find a pair of indexes with the shortest distance.

    Args:
        arr1: (N, 2).
        arr2: (M, 2).

    Return:
        a pair of indexes(tuple).
    """
    dis = ((arr1[:, None, :] - arr2[None, :, :]) ** 2).sum(-1)
    return np.unravel_index(np.argmin(dis, axis=None), dis.shape)


def merge_multi_segment(segments):
    """Merge multi segments to one list.

    Find the coordinates with min distance between each segment,
    then connect these coordinates with one thin line to merge all
    segments into one.

    Args:
        segments(List(List)): original segmentations in coco's json file.
            like [segmentation1, segmentation2,...],
            each segmentation is a list of coordinates.
    """
    s = []
    segments = [np.array(i).reshape(-1, 2) for i in segments]
    idx_list = [[] for _ in range(len(segments))]

    # record the indexes with min distance between each segment
    for i in range(1, len(segments)):
        idx1, idx2 = min_index(segments[i - 1], segments[i])
        idx_list[i - 1].append(idx1)
        idx_list[i].append(idx2)

    # use two round to connect all the segments
    for k in range(2):
        # forward connection
        if k == 0:
            for i, idx in enumerate(idx_list):
                # middle segments have two indexes
                # reverse the index of middle segments
                if len(idx) == 2 and idx[0] > idx[1]:
                    idx = idx[::-1]
                    segments[i] = segments[i][::-1, :]

                segments[i] = np.roll(segments[i], -idx[0], axis=0)
                segments[i] = np.concatenate([segments[i], segments[i][:1]])
                # deal with the first segment and the last one
                if i in [0, len(idx_list) - 1]:
                    s.append(segments[i])
                else:
                    idx = [0, idx[1] - idx[0]]
                    s.append(segments[i][idx[0]:idx[1] + 1])

        else:
            for i in range(len(idx_list) - 1, -1, -1):
                if i not in [0, len(idx_list) - 1]:
                    idx = idx_list[i]
                    nidx = abs(idx[1] - idx[0])
                    s.append(segments[i][nidx:])
    return s


def convert_coco2yolo(json_paths, save_dir, use_segments=True):
    save_dir = Path(save_dir)

    # Import json
    for json_file in sorted(list(json_paths)):
        json_file = Path(json_file)
        image_list = []
        makedirs(Path(save_dir) / "labels")
        fn = (
            Path(save_dir) / "labels" / json_file.stem.replace(
                "instances_", "")
        )  # folder name
        fn.mkdir()
        with open(json_file) as f:
            data = json.load(f)

        # Create image dict
        images = {"%g" % x["id"]: x for x in data["images"]}
        # Create image-annotations dict
        imgToAnns = defaultdict(list)
        for ann in data["annotations"]:
            imgToAnns[ann["image_id"]].append(ann)
        makedirs(save_dir / "images" / json_file.stem)

        # Write labels file
        for img_id, anns in tqdm(imgToAnns.items(),
                                 desc=f"Annotations {json_file}"):
            img = images["%g" % img_id]
            h, w, f = img["height"], img["width"], img["file_name"]
            image_list.append("./images/{}/{}".format(json_file.stem, f))

            bboxes = []
            segments = []
            for ann in anns:
                if ann["iscrowd"]:
                    continue
                # The COCO box format is
                # [top left x, top left y, width, height]
                box = np.array(ann["bbox"], dtype=np.float64)
                box[:2] += box[2:] / 2  # xy top-left corner to center
                box[[0, 2]] /= w  # normalize x
                box[[1, 3]] /= h  # normalize y
                if box[2] <= 0 or box[3] <= 0:  # if w <= 0 and h <= 0
                    continue

                cls = ann["category_id"]
                box = [cls] + box.tolist()
                if box not in bboxes:
                    bboxes.append(box)
                # Segments
                if use_segments:
                    if len(ann["segmentation"]) > 1:
                        s = merge_multi_segment(ann["segmentation"])
                        s = (
                            (np.concatenate(s, axis=0) / np.array([w, h]))
                            .reshape(-1)
                            .tolist()
                        )
                    else:
                        s = [
                            j for i in ann["segmentation"] for j in i
                        ]  # all segments concatenated
                        s = (
                            (np.array(s).reshape(-1, 2) / np.array([w, h]))
                            .reshape(-1)
                            .tolist()
                        )
                    s = [cls] + s
                    if s not in segments:
                        segments.append(s)

            # Write
            with open((fn / f).with_suffix(".txt"), "a") as file:
                for i in range(len(bboxes)):
                    line = (
                        *(segments[i] if use_segments else bboxes[i]),
                    )  # cls, box or segments
                    file.write(("%g " * len(line)).rstrip() % line + "\n")

        with open(
                (fn.parent.parent
                 / json_file.name).with_suffix(".txt"), "a") as file:
            file.write("\n".join(image_list) + "\n")


def labelme2voc(input_dir, output_dir, labels, noviz=False):
    subprocess.call("rm -rf {}".format(output_dir), shell=True)
    os.makedirs(output_dir)
    os.makedirs(osp.join(output_dir, "JPEGImages"))
    os.makedirs(osp.join(output_dir, "SegmentationClass"))
    os.makedirs(osp.join(output_dir, "SegmentationClassPNG"))
    if not noviz:
        os.makedirs(osp.join(output_dir, "SegmentationClassVisualization"))
    os.makedirs(osp.join(output_dir, "SegmentationObject"))
    os.makedirs(osp.join(output_dir, "SegmentationObjectPNG"))
    if not noviz:
        os.makedirs(osp.join(output_dir, "SegmentationObjectVisualization"))
    print("Creating dataset:", output_dir)

    class_names = []
    class_name_to_id = {}
    for i, line in enumerate(open(labels).readlines()):
        class_id = i - 1  # starts with -1
        class_name = line.strip()
        class_name_to_id[class_name] = class_id
        if class_id == -1:
            assert class_name == "__ignore__"
            continue
        elif class_id == 0:
            assert class_name == "_background_"
        class_names.append(class_name)
    class_names = tuple(class_names)
    print("class_names:", class_names)
    out_class_names_file = osp.join(output_dir, "class_names.txt")
    with open(out_class_names_file, "w") as f:
        f.writelines("\n".join(class_names))
    print("Saved class_names:", out_class_names_file)

    for filename in glob.glob(osp.join(input_dir, "*.json")):
        print("Generating dataset from:", filename)

        label_file = labelme.LabelFile(filename=filename)

        base = osp.splitext(osp.basename(filename))[0]
        out_img_file = osp.join(output_dir, "JPEGImages", base + ".jpg")
        out_cls_file = osp.join(output_dir, "SegmentationClass", base + ".npy")
        out_clsp_file = osp.join(
            output_dir, "SegmentationClassPNG", base + ".png")
        if not noviz:
            out_clsv_file = osp.join(
                output_dir,
                "SegmentationClassVisualization",
                base + ".jpg",
            )
        out_ins_file = osp.join(
            output_dir, "SegmentationObject", base + ".npy")
        out_insp_file = osp.join(
            output_dir, "SegmentationObjectPNG", base + ".png")
        if not noviz:
            out_insv_file = osp.join(
                output_dir,
                "SegmentationObjectVisualization",
                base + ".jpg",
            )

        img = labelme.utils.img_data_to_arr(label_file.imageData)
        imgviz.io.imsave(out_img_file, img)

        cls, ins = labelme.utils.shapes_to_label(
            img_shape=img.shape,
            shapes=label_file.shapes,
            label_name_to_value=class_name_to_id,
        )
        ins[cls == -1] = 0  # ignore it.

        # class label
        labelme.utils.lblsave(out_clsp_file, cls)
        np.save(out_cls_file, cls)
        if not noviz:
            clsv = imgviz.label2rgb(
                cls,
                imgviz.rgb2gray(img),
                label_names=class_names,
                font_size=15,
                loc="rb",
            )
            imgviz.io.imsave(out_clsv_file, clsv)

        # instance label
        labelme.utils.lblsave(out_insp_file, ins)
        np.save(out_ins_file, ins)
        if not noviz:
            instance_ids = np.unique(ins)
            instance_names = [str(i) for i in range(max(instance_ids) + 1)]
            insv = imgviz.label2rgb(
                ins,
                imgviz.rgb2gray(img),
                label_names=instance_names,
                font_size=15,
                loc="rb",
            )
            imgviz.io.imsave(out_insv_file, insv)
