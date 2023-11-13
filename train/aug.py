from functools import lru_cache

from imgaug import augmenters as iaa
import numpy as np
from PIL import Image
from pybsc.image_utils import mask_to_bbox
from pybsc.image_utils import rescale
from pybsc.image_utils import resize_keeping_aspect_ratio_wrt_longside
from pybsc.image_utils import rotate
from pybsc.image_utils import squared_padding_image


@lru_cache(maxsize=None)
def cached_imread(img_path, image_width=300):
    pil_img = Image.open(img_path)
    img = np.array(pil_img)
    try:
        img, mask = img[..., :3], img[..., 3]
    except IndexError:
        mask = 255 * np.ones((pil_img.height, pil_img.width), dtype=np.uint8)
    pil_mask = Image.fromarray(mask)
    pil_mask = resize_keeping_aspect_ratio_wrt_longside(
        pil_mask, image_width, interpolation="nearest"
    )
    pil_img = Image.fromarray(img)
    pil_img = resize_keeping_aspect_ratio_wrt_longside(
        pil_img, image_width, interpolation="bilinear"
    )
    return pil_img, pil_mask


def create_instance_image(instance_id, size):
    w, h = size
    return Image.fromarray(instance_id * np.ones((h, w), dtype=np.int32))


def random_rotate(pil_img, mask=None, angle=360):
    degrees = np.random.uniform(low=-angle, high=angle)
    return rotate(pil_img, mask, degrees)


def random_rescale(pil_img, mask=None, min_scale=0.2, max_scale=0.5):
    scale = np.random.uniform(min_scale, max_scale)
    return rescale(pil_img, mask, scale)


def random_crop_with_size(pil_img, image_width=300):
    w, h = pil_img.size
    if w < image_width or h < image_width:
        cv_img = squared_padding_image(np.array(pil_img), image_width)
        pil_img = Image.fromarray(cv_img)
        w, h = pil_img.size
    if w - image_width > 0:
        x = np.random.randint(0, w - image_width)
    else:
        x = 0
    if h - image_width > 0:
        y = np.random.randint(0, h - image_width)
    else:
        y = 0
    crop_img = pil_img.crop((x, y, x + image_width, y + image_width))
    return crop_img


def create_shifted_stack(
        image, num_stacks=3, shift_range=(-0.2, 0.2), **kwargs):
    shift_range = (
        int(image.size[1] * shift_range[0]),
        int(image.size[1] * shift_range[1]),
    )
    shifts = np.array(
        np.random.uniform(*shift_range, size=num_stacks - 1), "i")
    new_height = image.height * num_stacks + np.sum(shifts)
    new_image = Image.new("RGBA", (image.width, new_height))
    instance_mask = create_instance_image(0, (image.width, new_height))
    for i in range(num_stacks):
        if i >= 1:
            offset = (0, i * (image.height + shifts[i - 1]))
        else:
            offset = (0, i * (image.height))
        rgb_image, alpha_mask = custom_aug(
            image.convert("RGB"), image.split()[3], **kwargs
        )
        rgba_image = Image.merge("RGBA", (*rgb_image.split(), alpha_mask))
        new_image.paste(rgba_image, offset, rgba_image)
        instance_mask.paste(
            create_instance_image(i + 1, image.size), offset, rgba_image
        )
    rgb_image = new_image.convert("RGB")
    alpha_mask = new_image.split()[3]
    return rgb_image, alpha_mask, instance_mask


def custom_aug(pil_img, pil_mask, min_scale, max_scale, max_angle):
    if np.random.uniform(0, 1.0) > 0.5:
        aug = iaa.MultiplyAndAddToBrightness(mul=(0.1, 2.0), add=(-30, 30))
        pil_img = aug.augment_image(np.array(pil_img, dtype=np.uint8))
        pil_img = Image.fromarray(pil_img)

        # aug = iaa.AddToSaturation()
        aug = iaa.AddToHueAndSaturation((-50, 50), per_channel=True)
        # aug = iaa.GammaContrast((0.5, 2.0))
        pil_img = aug.augment_image(np.array(pil_img, dtype=np.uint8))
        pil_img = Image.fromarray(pil_img)

    if np.random.uniform(0, 1.0) > 0.5:
        # aug = iaa.PiecewiseAffine(scale=(0.01, 0.05))
        aug = iaa.ElasticTransformation()
        _aug = aug._to_deterministic()
        pil_img = _aug.augment_image(np.array(pil_img, dtype=np.uint8))
        pil_img = Image.fromarray(pil_img)
        pil_mask = _aug.augment_image(np.array(pil_mask, dtype=np.uint8))
        pil_mask = Image.fromarray(pil_mask)

    if np.random.uniform(0, 1.0) > 0.5:
        aug = iaa.Cutout(
            nb_iterations=(1, 5),
            size=0.2,
            squared=False,
            fill_mode="constant",
            cval=(0, 255),
            fill_per_channel=0.5,
        )
        _aug = aug._to_deterministic()
        pil_img = _aug.augment_image(np.array(pil_img, dtype=np.uint8))
        pil_img = Image.fromarray(pil_img)

    if pil_img.size[0] == 0 or pil_img.size[1] == 0:
        print("size 0 after rotate. retry.")
        return None, None
    return pil_img, pil_mask


def random_binpacking(
    pil_bg_img,
    img_paths,
    low=3,
    high=20,
    p=None,
    targets=None,
    image_width=300,
    max_angle=360,
    min_scale=0.2,
    max_scale=0.5,
    acc_cnt=None,
    cnt_dict=None,
):
    pil_bg_img = pil_bg_img.copy()
    size = np.random.randint(low, high)
    names = []
    rectangles = []
    pil_imgs = []
    while len(rectangles) < size:
        path = np.random.choice(img_paths, p=p)
        pil_img, pil_mask = cached_imread(path, image_width=image_width)
        name = path.parent.name.lower()
        if targets is not None:
            if name not in targets:
                name = "others"

        pil_img, pil_mask = random_rescale(
            pil_img, mask=pil_mask, min_scale=min_scale, max_scale=max_scale
        )
        if pil_img.size[0] == 0 or pil_img.size[1] == 0:
            print("size 0 after rescale. retry")
            return None, None

        instance_img = None
        if np.random.uniform(0.0, 1.0) < 0.3:
            rgba_image = Image.merge("RGBA", (*pil_img.split(), pil_mask))
            num_stacks = np.random.randint(2, 7)
            pil_img, pil_mask, instance_img = create_shifted_stack(
                rgba_image,
                num_stacks=num_stacks,
                shift_range=(-0.2, 0.0),
                min_scale=min_scale,
                max_scale=max_scale,
                max_angle=max_angle,
            )
        else:
            pil_img, pil_mask = custom_aug(
                pil_img, pil_mask, min_scale, max_scale, max_angle
            )
            if pil_img is None:
                continue

        degrees = np.random.uniform(low=-max_angle, high=max_angle)
        pil_img, pil_mask = rotate(pil_img, pil_mask, degrees)
        if instance_img is not None:
            instance_img = instance_img.rotate(
                degrees, resample=Image.NEAREST, expand=True
            )

        try:
            y1, x1, y2, x2 = mask_to_bbox(pil_mask)
        except ValueError as e:
            print("error on mask_to_bbox")
            print(str(e))
            continue
        h = y2 - y1
        w = x2 - x1
        pil_imgs.append((pil_img, pil_mask, instance_img))
        rectangles.append((w, h))
        names.append(name)

        if cnt_dict is not None and acc_cnt is not None:
            acc_cnt[name] += 1
            sum(acc_cnt.values())
            max_value = max(acc_cnt.values())
            probs = []
            new_names = []
            for key, value in acc_cnt.items():
                # probs.append(1.0 / (value + 1.0))
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
                    p[idx] = name2prob["others"] / cnt_dict["others"]
                else:
                    p[idx] = name2prob[obj_name] / cnt_dict[obj_name]

    bboxes = []
    new_names = []
    instance_mask = Image.fromarray(
        np.zeros((pil_bg_img.size[1], pil_bg_img.size[0]), dtype=np.int32)
    )
    instance_id = 1
    index = 0
    for _ in range(50):
        if len(rectangles) <= len(bboxes):
            break
        x, y = select_position(
            rectangles[index], bboxes, image_width, image_width, 0.2)
        if x is None:
            continue
        w, h = rectangles[index]
        pil_img, pil_mask, instance_img = pil_imgs[index]
        y1, x1, y2, x2 = mask_to_bbox(pil_mask)
        pil_bg_img.paste(pil_img, (x - x1, y - y1), pil_mask)
        pil_mask = Image.fromarray(
            255 * np.array(np.array(pil_mask) > 0, dtype=np.uint8)
        )
        if instance_img is None:
            instance_mask.paste(
                create_instance_image(instance_id, pil_img.size),
                (x - x1, y - y1),
                pil_mask,
            )
            bboxes.append([x, y, x + w, y + h])
            new_names.append(names[index])
            instance_id += 1
        else:
            instance_img = np.array(instance_img, dtype=np.int32)
            instance_mask.paste(
                Image.fromarray(instance_img + instance_id),
                (x - x1, y - y1), pil_mask
            )
            num_stacks = np.max(instance_img) + 1
            for _ in range(num_stacks):
                bboxes.append([x, y, x + w, y + h])
                new_names.append(names[index])
            instance_id += num_stacks
        index += 1

        if index >= len(rectangles):
            break
    bboxes = [[y1, x1, y2, x2] for x1, y1, x2, y2 in bboxes]
    return pil_bg_img, bboxes, new_names, instance_mask


def calculate_iou_vectorized(new_box, existing_boxes):
    if len(existing_boxes) == 0:
        return np.zeros(1)
    new_box = np.array(new_box)
    existing_boxes = np.array(existing_boxes)
    intersect_min = np.maximum(existing_boxes[:, :2], new_box[:2])
    intersect_max = np.minimum(existing_boxes[:, 2:], new_box[2:])
    intersect_dim = np.maximum(intersect_max - intersect_min, 0)
    intersect_area = intersect_dim[:, 0] * intersect_dim[:, 1]
    new_box_area = (new_box[2] - new_box[0]) * (new_box[3] - new_box[1])
    existing_boxes_area = (existing_boxes[:, 2] - existing_boxes[:, 0]) * (
        existing_boxes[:, 3] - existing_boxes[:, 1]
    )
    union_area = new_box_area + existing_boxes_area - intersect_area
    iou = intersect_area / union_area
    return iou


def select_position(
        size, bboxes, bg_width, bg_height, iou_threshold, max_attempts=100):
    img_width, img_height = size

    for _ in range(max_attempts):
        x = np.random.randint(-img_width + 1, bg_width - 1)
        y = np.random.randint(-img_height + 1, bg_height - 1)
        new_box = [x, y, x + img_width, y + img_height]
        ious = calculate_iou_vectorized(new_box, bboxes)
        if np.all(ious <= iou_threshold):
            return x, y
    return None, None
