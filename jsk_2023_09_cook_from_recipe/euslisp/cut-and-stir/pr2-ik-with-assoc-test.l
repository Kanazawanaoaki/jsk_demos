(load "package://pr2eus/pr2-interface.l")
(load "models/arrow-object.l")
(load "models/room73b2-kettle-object.l")

(setq *pr2* (pr2))
(setq *arrow* (arrow))
(setq *kettle* (room73b2-kettle))

(send *pr2* :reset-pose)
(send *kettle* :newcoords (send (send (send *pr2* :rarm :end-coords) :copy-worldcoords) :transform (send (send (car (send *kettle* :handle)) :coords) :inverse-transformation)))
(send *pr2* :rarm :end-coords :assoc *kettle*)

(send *arrow* :newcoords (make-coords :pos #f(600 -50 700) :rpy #f(1.571 0.0 1.571)))

(objects (list *pr2* *arrow* *kettle*))

(defun ik-with-arm (&optional (target-coords (send *arrow* :copy-worldcoords)))
  (send *arrow* :newcoords (send target-coords :copy-worldcoords))
  (send *pr2* :rarm :inverse-kinematics (send *arrow* :copy-worldcoords)
        :link-list (list
                    (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
        :move-target (send *pr2* :rarm :end-coords)
        :debug-view t
        )
  (format t "kettle coords : ~A ~%" (send *kettle* :copy-worldcoords))
  (format t "kettle attention coords : ~A ~%" (send (car (send *kettle* :attention)) :copy-worldcoords))
  )

(defun ik-with-kettle (&optional (target-coords (make-coords :pos #f(599.96 -50.0 505.0) :rpy #f(1.571 1.151e-10 0.0))))
  (send *arrow* :newcoords (send target-coords :copy-worldcoords))
  (send *pr2* :rarm :inverse-kinematics (send *arrow* :copy-worldcoords)
        :link-list (list
                    (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
        :move-target *kettle*
        :debug-view t
        )
  )

(defun ik-with-attention (&optional (target-coords (make-coords :pos #f(719.981 -49.976 604.976) :rpy #f(1.571 1.671e-11 0.0))))
  (send *arrow* :newcoords (send target-coords :copy-worldcoords))
  (send *pr2* :rarm :inverse-kinematics (send *arrow* :copy-worldcoords)
        :link-list (list
                    (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
        :move-target (car (send *kettle* :attention))
        :debug-view t
        )
  )
