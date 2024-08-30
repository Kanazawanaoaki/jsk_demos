#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/73b2-kitchen-coords.l")

;; set objects
(unless (boundp '*kitchen-object*)
  (progn
    (load "models/room73b2-kitchen-object.l")
    (setq *kitchen-object* (room73b2-kitchen))
    ))

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

(defun show-object-init (&key (reset-obj-cds t) (init-cds t) (type :curry))
  (reset-view-list)

  ;; (dissoc-object *kitchen-object*)
  ;; (send *kitchen-object* :newcoords (make-coords :pos #f(900 0 0) :rpy (float-vector pi 0 0)))

  (set-object *kitchen-object* (make-coords)) ;; 300.0 8720.0 30010.0  in world

  ;; (setq *kitchen-spot-coords* (make-coords :pos (float-vector 870.0 -180.0 -10.0) :rpy (float-vector pi 0 0))) ;; fix
  (setq *kitchen-spot-coords* (make-coords :pos (float-vector 870.0 -190.0 -10.0) :rpy (float-vector pi 0 0))) ;; fix v3
  ;; (setq *stove-spot-coords* (make-coords :pos (float-vector 1000.0 -720.0 -10.0) :rpy (float-vector pi 0 0))) ;; fix
  ;; (setq *stove-spot-coords* (make-coords :pos (float-vector 1000.0 -810.0 -10.0) :rpy (float-vector pi 0 0))) ;; fix v2
  (setq *stove-spot-coords* (make-coords :pos (float-vector 1000.0 -796.0 -10.0) :rpy (float-vector pi 0 0))) ;; fix v3
  (setq *sink-spot-coords* (make-coords :pos (float-vector 820.0 370.0 -10.0) :rpy (float-vector pi 0 0))) ;; fix

  (set-object *arrow1* *kitchen-spot-coords*)
  (set-object *arrow2* *stove-spot-coords*)
  (set-object *arrow3* *sink-spot-coords*)

  ;; kitchen object
  ;; set global coords
  (when init-cds
    (73b2-kitchen-coords-init :type type))

  ;; set tools
  (when reset-obj-cds
    (73b2-kitchen-obj-init :type type :kitchen-coords *kitchen-spot-coords*)
    )

  ;; stove object
  ;; set global coords
  (when init-cds
    (73b2-stove-coords-init :type type))

  ;; set tools
  (when reset-obj-cds
    (73b2-stove-obj-init :type type :stove-coords *stove-spot-coords*)
    )

  (objects *view-objects*)
  )

(show-object-init)
(warn "please run (show-object-init :type :curry)~%")
