from math import atan2
from math import cos
from math import pi
from math import sin
from math import sqrt

import cv2
import numpy as np
from pybsc.image_utils import rotate
from rembg import remove


def draw_axis(img, p_, q_, colour, scale):
    p = list(p_)
    q = list(q_)

    angle = atan2(p[1] - q[1], p[0] - q[0])  # angle in radians
    hypotenuse = sqrt((p[1] - q[1]) * (p[1] - q[1]) + (p[0] - q[0]) * (p[0] - q[0]))
    # Here we lengthen the arrow by a factor of scale
    q[0] = p[0] - scale * hypotenuse * cos(angle)
    q[1] = p[1] - scale * hypotenuse * sin(angle)
    cv2.line(img, (int(p[0]), int(p[1])), (int(q[0]), int(q[1])), colour, 1, cv2.LINE_AA)
    # create the arrow hooks
    p[0] = q[0] + 9 * cos(angle + pi / 4)
    p[1] = q[1] + 9 * sin(angle + pi / 4)
    cv2.line(img, (int(p[0]), int(p[1])), (int(q[0]), int(q[1])), colour, 1, cv2.LINE_AA)
    p[0] = q[0] + 9 * cos(angle - pi / 4)
    p[1] = q[1] + 9 * sin(angle - pi / 4)
    cv2.line(img, (int(p[0]), int(p[1])), (int(q[0]), int(q[1])), colour, 1, cv2.LINE_AA)


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
    cntr = (int(mean[0,0]), int(mean[0,1]))
    # cv2.circle(img, cntr, 3, (255, 0, 255), 2)
    p1 = (cntr[0] + 0.02 * eigenvectors[0,0] * eigenvalues[0,0], cntr[1] + 0.02 * eigenvectors[0,1] * eigenvalues[0,0])
    p2 = (cntr[0] - 0.02 * eigenvectors[1,0] * eigenvalues[1,0], cntr[1] - 0.02 * eigenvectors[1,1] * eigenvalues[1,0])
    draw_axis(img, cntr, p1, (0, 255, 0), 1)
    draw_axis(img, cntr, p2, (255, 255, 0), 5)
    angle = atan2(eigenvectors[0,1], eigenvectors[0,0])
    return angle


def remove_background(img, path_name=None):
    img = remove(img)

    kernel = np.ones((21, 21))
    mask = 255 * np.array(img[..., 3] > 0, dtype=np.uint8)
    img_dil = cv2.erode(mask, kernel, iterations=10)
    img_opening = cv2.dilate(img_dil, kernel, iterations=10)
    y, x = np.where(img_opening > 0)

    x1 = np.min(x)
    x2 = np.max(x)
    y1 = np.min(y)
    y2 = np.max(y)
    img = img[y1:y2, x1:x2]

    mask = ((img[..., 3] > 0).copy())
    mask = 255 * np.array(mask, dtype=np.uint8)

    img_dil = cv2.erode(mask, kernel, iterations=10)
    img_opening = cv2.dilate(img_dil, kernel, iterations=10)
    mask = img_opening

    contours, _ = cv2.findContours(
        mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)

    areas = [cv2.contourArea(c) for i, c in enumerate(contours)]
    contour = contours[np.argmax(areas)]
    hoge_img = img.copy()[..., :3]

    rect = cv2.minAreaRect(contour)
    box = cv2.boxPoints(rect)
    box = np.int0(box)

    hoge_img = np.array(hoge_img, dtype=np.uint8)
    hoge_img = cv2.drawContours(
        hoge_img, contours,
        int(np.argmax(areas)), (0, 0, 255), 3)
    angle = get_orientation(contour, hoge_img)
    angle = get_orientation(box.reshape(-1, 1, 2), hoge_img)
    if path_name is not None:
        cv2.imwrite(str(path_name), hoge_img)
    angle = np.rad2deg(angle)
    img = rotate(img, angle=angle)
    return img
