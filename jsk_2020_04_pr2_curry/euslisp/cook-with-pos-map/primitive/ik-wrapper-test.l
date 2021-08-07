(require :pr2-interface "package://pr2eus/pr2-interface.l")
(unless (boundp '*pr2*) (setq *pr2* (instance pr2-sensor-robot :init)))

;; (defun hoge (&rest args &key (arm :rarm) &allow-other-keys)
;;   (setq tmp (send *pr2* arm))
;;   )



;; IK-wrapperを作るtest
(load "models/arrow-object.l")
(setq *arrow* (arrow))
(send *arrow* :newcoords (make-coords :pos (float-vector 700 -150 1000)))

(objects (list *pr2* *arrow*))


(defun ik-test (coords &key (rotate-flag t) (arm :rarm))
  (send *pr2* arm :inverse-kinematics
        coords
        :rotation-axis rotate-flag
        :debug-view t)
  (send *viewer* :draw-objects)
  )

(defun mo-test (coords &key (rotate-flag t) (arm :rarm) (target (send *pr2* :rarm :end-coords)))
  (send *pr2* arm :inverse-kinematics
        coords
        :move-target target
        :rotation-axis rotate-flag
        :debug-view t)
  (send *viewer* :draw-objects)
  )

(warn "please run like (ik-test *arrow* :rotate-flag t :arm :larm) ~%")
(warn "please run like (mo-test *arrow* :rotate-flag t) ~%")
