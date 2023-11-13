import pathlib
from pathlib import Path

import cv2
from moviepy.video.io.ffmpeg_writer import FFMPEG_VideoWriter
import numpy as np
import PIL.Image
from pybsc.colormap import cmap
from pybsc.image_utils import non_maximum_suppression
from pybsc.image_utils import resize_keeping_aspect_ratio_wrt_longside
from pybsc.image_utils import squared_padding_image
from pybsc.image_utils import tile_image
from pybsc import load_json
from pybsc.visualizations.bbox import visualize_bboxes
import torch
from tqdm import tqdm


def prepare(imgs,
            min_size=512,
            max_size=800,):
    prepared_imgs = []
    sizes = []
    scales = []
    for img in imgs:
        img = img.transpose(2, 0, 1)
        _, H, W = img.shape

        scale = 1.

        if min_size:
            scale = min_size / min(H, W)

        if max_size and scale * max(H, W) > max_size:
            scale = max_size / max(H, W)

        img = img.transpose(1, 2, 0)
        img = cv2.resize(img, None, fx=scale, fy=scale)
        img = img.transpose(2, 0, 1)

        img = img.astype(np.float32, copy=False)

        prepared_imgs.append(img / 255.0 - 0.5)
        sizes.append((H, W))
        scales.append(scale)
    return prepared_imgs, sizes, scales


def inference_movie(
        paths,
        model, device, class_names,
        enable_tile=False,
        input_size=512,
        window_size=200,
        square_padding=False):
    model.eval()
    if len(paths) == 0:
        raise RuntimeError('len(paths) should be greater than 0.')
    result_list = []
    for img_file in tqdm(paths):
        if isinstance(img_file, str) or isinstance(
                img_file, pathlib.PosixPath):
            org_img = np.array(PIL.Image.open(str(img_file)))
        else:
            org_img = img_file
        out_result = inference_img(
            org_img, model, device, class_names,
            enable_tile, input_size, window_size, square_padding)
        result_list.append(out_result)
    return result_list


def inference_img(
        img,
        model, device, class_names,
        enable_tile=False,
        input_size=512,
        window_size=200,
        square_padding=False,
        box_order='xyxy'):
    class_names = np.array(class_names)
    if isinstance(img, str) or isinstance(img, pathlib.PosixPath):
        org_img = np.array(PIL.Image.open(str(img)))
    else:
        org_img = img
    if enable_tile is False:
        if square_padding:
            org_img, (offset_x, offset_y) = squared_padding_image(
                org_img,
                return_offset=True)
        resized_org_img, first_scale = \
            resize_keeping_aspect_ratio_wrt_longside(
                org_img, input_size,
                return_scale=True)
        images, _, scales = prepare([resized_org_img])
        img = images[0]
        scale = scales[0] * first_scale
        img = torch.as_tensor(img, dtype=torch.float32).to(device)[None, ]
        with torch.no_grad():
            outputs = model(img)
        result = {
            'scores': outputs[0]['scores'].detach().cpu().numpy(),
            'labels': outputs[0]['labels'].detach().cpu().numpy(),
            'label_names': class_names[
                outputs[0]['labels'].detach().cpu().numpy()],
            'class_names': class_names,
        }
        if square_padding:
            result['boxes'] = outputs[0][
                'boxes'].detach().cpu().numpy() / scale \
                - np.array([offset_x, offset_y, offset_x, offset_y])
        else:
            result['boxes'] = outputs[0][
                'boxes'].detach().cpu().numpy() / scale
        return result
    else:
        h, w, _ = org_img.shape
        tiles = tile_image((w, h), (input_size, input_size),
                           window_size=window_size)
        input_imgs = [org_img[y:y + hTile, x:x + wTile]
                      for x, y, hTile, wTile in tiles]
        images, _, scales = prepare(input_imgs)

        bboxes = []
        labels = []
        scores = []
        for jjj, (img, scale) in enumerate(zip(images, scales)):
            with torch.no_grad():
                img = torch.as_tensor(
                    img, dtype=torch.float32).to(device)[None, ]
                outputs = model(img)
            x, y, _, _ = tiles[jjj]
            scores.append(outputs[0]['scores'].detach().cpu().numpy())
            if box_order == 'xyxy':
                bboxes.append(outputs[0][
                    'boxes'].detach().cpu().numpy() / scale + np.array(
                        [x, y, x, y]))
            elif box_order == 'yxyx':
                if len(outputs[0]['boxes']) > 0:
                    bboxes.append(
                        outputs[0]['boxes'].detach().cpu().numpy()[
                            :, [1, 0, 3, 2]] / scale + np.array([y, x, y, y]))
            else:
                raise NotImplementedError('Please implement box_order.')
            labels.append(outputs[0]['labels'].detach().cpu().numpy())
        labels = np.concatenate(labels)
        return {
            'boxes': np.concatenate(bboxes, axis=0),
            'scores': np.concatenate(scores),
            'labels': labels,
            'label_names': class_names[labels],
            'class_names': class_names,
        }


def visualize_inference(img, data, gt_data=None, nms_thresh=0.3,
                        score_thresh=0.5,
                        ignore_labels=None):
    img = img.copy()
    ignore_labels = ignore_labels or []
    scores = np.array(data['scores'], 'f')
    bboxes = np.array(data['boxes'], 'f')
    if len(bboxes) > 0:
        bboxes = bboxes[:, [1, 0, 3, 2]]
    labels = np.array(data['labels'], 'i')
    label_names = np.array(data['label_names'])
    indices = non_maximum_suppression(
        bboxes, nms_thresh, score=scores)
    indices = indices[scores[indices] > score_thresh]
    viz_labels = []
    viz_bboxes = []
    cnt = 0
    for i in indices:
        score = scores[i]
        if label_names[i] not in ignore_labels:
            viz_labels.append(
                (cnt, label_names[i] + " %.2f" % score, cmap(labels[i])))
            viz_bboxes.append((None, bboxes[i]))
            cnt += 1
    viz = img
    if gt_data is not None:
        gt_bboxes = np.array(gt_data['boxes'], 'f')
        if len(gt_bboxes) > 0:
            gt_bboxes = gt_bboxes[:, [1, 0, 3, 2]]
        gt_viz_labels = []
        new_gt_bboxes = []
        cnt = 0
        for label_name, label_idx, gt_bbox in zip(gt_data['label_names'],
                                                  gt_data['labels'],
                                                  gt_bboxes):
            if label_name not in ignore_labels:
                gt_viz_labels.append((cnt, label_name, cmap(label_idx)))
                new_gt_bboxes.append((None, gt_bbox))
                cnt += 1
        visualize_bboxes(viz, new_gt_bboxes, gt_viz_labels, font_ratio=40,
                         box_color=(0, 0, 255))
    viz = visualize_bboxes(viz, viz_bboxes, viz_labels, font_ratio=40,
                           box_color=(0, 255, 0))
    return viz


def labelme2data(json_path, class_names):
    data = load_json(json_path)
    bboxes = []
    labels = []
    for shape in data['shapes']:
        (x1, y1), (x2, y2) = shape['points']
        if y1 > y2:
            y1, y2 = y2, y1
        if x1 > x2:
            x1, x2 = x2, x1
        y1 = min(data['imageHeight'], max(0, y1))
        y2 = min(data['imageHeight'], max(0, y2))
        x1 = min(data['imageWidth'], max(0, x1))
        x2 = min(data['imageWidth'], max(0, x2))
        label_name = shape['label'].lower()
        if label_name not in class_names:
            continue
        bboxes.append([x1, y1, x2, y2])
        labels.append(class_names.index(label_name))
    class_names = np.array(class_names)
    return {
        'boxes': np.array(bboxes),
        'labels': labels,
        'label_names': class_names[labels],
        'class_names': class_names,
    }


def visualize_movie(
        paths,
        result_list,
        output_videopath,
        write_image=True,
        gt_data_list=None, nms_thresh=0.3,
        score_thresh=0.5,
        ignore_labels=None):
    dt = 0.1
    fps = 1.0 / dt

    if len(paths) == 0:
        raise RuntimeError('len(paths) should be greater than 0.')
    if gt_data_list is None:
        gt_data_list = [None] * len(paths)
    writer = None
    cnt = 0
    H, W = None, None
    for (img_file, out_result, gt_data) in tqdm(
            zip(paths, result_list, gt_data_list),
            total=len(paths)):
        if isinstance(img_file, str) or isinstance(
                img_file, pathlib.PosixPath):
            org_img = np.array(PIL.Image.open(str(img_file)))
        else:
            org_img = img_file
        viz = visualize_inference(
            org_img, out_result, gt_data, nms_thresh=nms_thresh,
            score_thresh=score_thresh,
            ignore_labels=ignore_labels)
        if write_image is True:
            img_path = Path(output_videopath)
            cv2.imwrite('{0}-{1:04}.jpg'.format(img_path.parent, cnt),
                        viz[..., ::-1])
        if H is None:
            H, W, _ = org_img.shape
        if writer is None:
            writer = FFMPEG_VideoWriter(
                str(output_videopath), (W, H), fps, logfile=None)
        viz = squared_padding_image(viz)
        viz = cv2.resize(viz, (W, H))
        writer.write_frame(viz)
        cnt += 1
    writer.close()
