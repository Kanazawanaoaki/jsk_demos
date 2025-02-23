#!/usr/bin/env roseus

(require :pr2-cook-utils "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2_cut_food.l")


(require :kanazawa-roseus-utils "package://jsk_2023_09_cook_from_recipe/euslisp/kanazawa-roseus-utils.l")

(setq kinect-tag-coords (make-coords :pos #f(568.333 98.96 986.93) :rpy #f(0.008 -0.009 -0.002)))

;; (defun calc-calib-camera-cds (kinect-tag-cds mega-tag-cds mega-link-cds)
;;   (setq mega-link->tag (calc-rel-from-base-target mega-link-cds mega-tag-cds))
;;   (setq true-mega-link-cds (calc-base-from-target-rel kinect-tag-cds mega-link->tag))
;;   true-mega-link-cds)

;; (defun calc-offset (base-link-cds camera-root-cds)
;;   (setq offset-cds (calc-rel-from-base-target base-link-cds camera-root-cds))
;;   offset-cds)

(setq calib-cds-1 (calc-calib-camera-cds kinect-tag-coords
                                         (make-coords :pos #f(548.397 55.111 972.27) :rpy #f(0.004 -0.063 0.013));; mega-tag-cds
                                         (make-coords :pos #f(150.424 -39.987 1501.446)
                                                      :rpy #f(5.914e-05 1.075 -4.066e-20));; mega-link-cds
                                         ))

(setq calib-cds-2 (calc-calib-camera-cds kinect-tag-coords
                                         (make-coords :pos #f(597.383 105.663 1010.609) :rpy #f(0.004 -0.049 0.015));; mega-tag-cds
                                         (make-coords :pos #f(199.806 10.812 1538.175) :rpy #f(-0.028 1.129 -0.036))
                                         ))

(print calib-cds-1)

(print calib-cds-2)

