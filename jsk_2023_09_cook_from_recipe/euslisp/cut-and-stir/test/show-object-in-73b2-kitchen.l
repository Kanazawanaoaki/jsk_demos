#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/73b2-kitchen-coords.l")

;; load objects
(unless (boundp '*knife*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/knife-new-attention.l")
    (setq *knife* (knife))
    ))

(unless (boundp '*peeler*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/peeler.l")
    (setq *peeler* (peeler))
    ))

(unless (boundp '*potato-peeler*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/potato-peeler.l")
    (setq *potato-peeler* (peeler))
    ))

(unless (boundp '*spatula*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/spatula.l")
    (setq *spatula* (spatula))
    ))

(unless (boundp '*ladle*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/ladle.l")
    (setq *ladle* (ladle))
    ))

(unless (boundp '*shelf-door*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/shelf-door.l")
    (setq *shelf-door* (shelf-door))
    ))

(unless (boundp '*cutting-board*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cutting-board.l")
    (setq *cutting-board* (cutting-board))
    ))

(unless (boundp '*mcup*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/measuring-cup-73b2.l")
    (setq *mcup* (measuring-cup-73b2))
    ))

(unless (boundp '*oil-dispenser*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/dispenser.l")
    (setq *oil-dispenser* (dispenser))
    ))

(unless (boundp '*bowl-1*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-1.l")
    (setq *bowl-1* (bowl-1))
    ))

(unless (boundp '*bowl-2*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-2.l")
    (setq *bowl-2* (bowl-2))
    ))

(unless (boundp '*bowl-3*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-3.l")
    (setq *bowl-3* (bowl-3))
    ))

(unless (boundp '*gray-bowl*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/gray-bowl.l")
    (setq *gray-bowl* (gray-bowl))
    ))

(unless (boundp '*green-bowl*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/green-bowl.l")
    (setq *green-bowl* (green-bowl))
    ))

(unless (boundp '*pot*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pot-73b2.l")
    (setq *pot* (cooking-pot))
    ))

(unless (boundp '*pan*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pan-73b2.l")
    (setq *pan* (cooking-pan))
    ))

(unless (boundp '*stove-kitchen-plane*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/stove-kitchen-plane.l")
    (setq *stove-kitchen-plane* (stove-kitchen-plane))
    ))

(unless (boundp '*kitchen-plane*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/kitchen-plane.l")
    (setq *kitchen-plane* (kitchen-plane :cube-x 570 :cube-y 690 :cube-z 10))
    ))

(unless (boundp '*arrow*)
  (progn
    (load "models/arrow-object.l")
    (setq *arrow* (arrow))
    ))

(unless (boundp '*kitchen-object*)
  (progn
    (load "models/room73b2-kitchen-object.l")
    (setq *kitchen-object* (room73b2-kitchen))
    ))

(defun show-object-init (&key (reset-obj-cds t) (init-cds t) (type :curry))
  (dissoc-object *kitchen-object*)
  (send *kitchen-object* :newcoords (make-coords :pos #f(900 0 0) :rpy (float-vector pi 0 0)))

  ;; kitchen object
  ;; set global coords
  (when init-cds
    (73b2-kitchen-coords-init :type type))

  ;; set tools
  (when reset-obj-cds
    (case type
          (:curry
           (dissoc-object *knife*)
           (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

           (dissoc-object *peeler*)
           (send *peeler* :newcoords (send *peeler-coords* :copy-worldcoords))

           (dissoc-object *potato-peeler*)
           (send *potato-peeler* :newcoords (send *potato-peeler-coords* :copy-worldcoords))

           (dissoc-object *spatula*)
           (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords))

           (dissoc-object *ladle*)
           (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords))

           (dissoc-object *pot*)
           (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))

           (send *kitchen-plane* :newcoords  (send *kitchen-plane-coords* :copy-worldcoords))

           ;; set equipment
           (dissoc-object *shelf-door*)
           (send *shelf-door* :newcoords (send *shelf-door-coords* :copy-worldcoords))

           (setq *shelf-look-coords* (send (send *shelf-door* :handle-handle0) :copy-worldcoords))

           (objects (list *kitchen-object* *pr2* *kitchen-plane* *peeler* *knife* *potato-peeler* *spatula* *ladle* *shelf-door*))
           )
          )
    )

  ;; stove object
  ;; set global coords
  (when init-cds
    (73b2-stove-coords-init :type type))

  ;; set tools
  (when reset-obj-cds
    (case type
          (:curry
           (print "TODO")
           )
          )
    )
  )

(show-object-init)
