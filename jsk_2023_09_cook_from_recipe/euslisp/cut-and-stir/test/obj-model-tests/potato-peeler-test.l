(load "package://jsk_2023_09_cook_from_recipe/euslisp/kanazawa-roseus-utils.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/potato-peeler.l")

(setq *potato-peeler* (potato-peeler))

(send *potato-peeler* :translate #f(0 0 100) :world)

(objects (list *potato-peeler*))

(defun view-coords ()
  (objects (list *potato-peeler*))
  (send (send *potato-peeler* :attention-attention0) :draw-on :flush t)
  (send (send *potato-peeler* :handle-handle0) :draw-on :flush t)
  )

(defun test-coords ()
  (setq test-cds (send *potato-peeler* :copy-worldcoords))
  (send test-cds :rotate (deg2rad -90) :x)
  (format t "obj coords ~A , set target coords is ~A ~%" (send *potato-peeler* :copy-worldcoords) (send test-cds :copy-worldcoords))
  (print (calc-object-rel-coords *potato-peeler* test-cds))
  )

(warn "please run (view-coords) or (test-coords)~%")
