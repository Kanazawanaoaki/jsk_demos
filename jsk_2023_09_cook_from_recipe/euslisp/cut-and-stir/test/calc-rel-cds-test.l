#!/usr/bin/env roseus

(require :kanazawa-roseus-utils "package://jsk_2023_09_cook_from_recipe/euslisp/kanazawa-roseus-utils.l")
(require :arrow-object "models/arrow-object.l")

;; set objects
(unless (boundp '*arrow1*)
  (progn
    (setq *arrow1* (arrow))
    ))

(unless (boundp '*arrow2*)
  (progn
    (setq *arrow2* (arrow))
    ))

(unless (boundp '*arrow3*)
  (progn
    (setq *arrow3* (arrow))
    ))


(setq base-coords (make-coords :pos (float-vector 740 -370 840) :rpy (float-vector pi 0 0)))
(setq target-coords (make-coords :pos #f(682.232 -349.307 852.929) :rpy #f(0.115 1.25 -1.37)))
(setq rel-coords  (make-coords :pos #f(57.768 -20.693 12.929) :rpy #f(-3.027 1.25 -1.37)))

(send *arrow1* :newcoords (send base-coords :copy-worldcoords))
(send *arrow2* :newcoords (send target-coords :copy-worldcoords))

(objects (list *arrow1* *arrow2* *arrow3*))


(setq current-rel-coords (calc-object-rel-coords base-coords target-coords))
(setq current-target-coords (calc-coords-from-rel base-coords rel-coords))
(setq current-base-coords (calc-object-base-coords target-coords rel-coords))
(format t "rel-coords ~A, ans ~A, dis ~A ~%" current-rel-coords rel-coords (calc-dis-two-coords current-rel-coords rel-coords))
(format t "target-coords ~A, ans ~A, dis ~A ~%" current-target-coords target-coords (calc-dis-two-coords current-target-coords target-coords))
c(format t "base-coords ~A, ans ~A, dis ~A ~%" current-base-coords base-coords (calc-dis-two-coords current-base-coords base-coords))



