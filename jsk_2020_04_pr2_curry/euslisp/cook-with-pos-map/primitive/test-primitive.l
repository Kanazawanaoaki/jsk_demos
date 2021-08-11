(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")


(defun set-hoge ()
  (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)
  (update-view)
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (send *viewer* :draw-objects)
  
  (setq *arrow* (arrow))
  (objects (list *scene* *pr2* *arrow*))
  (update-view)
  )

(set-hoge)

(warn "please run (move-arm-test-1) or (move-arm-test-2) ~%")

;; move-arm primitive
(defun move-arm-test-1 ()
  (send *arrow* :newcoords (make-coords :pos #f(500 8690 31000) :rpy #f(3.14 0 0)))
  
  (move-arm-ik (send *arrow* :copy-worldcoords))
  )

(defun move-arm-test-2 ()
  (send *arrow* :newcoords (make-coords :pos #f(500 8310 31000) :rpy #f(3.14 0 0)))
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm)
  )


;; move-gripper primitive
(defun move-gripper-test-1 ()
  (move-gripper-func 50)
  )

(defun move-gripper-test-2 ()
  (move-gripper-func 50 :arm :larm)
  )

;; move-head primitive
(defun move-head-test-1 ()
  (move-head-func :p-val 50)
  )

(defun move-head-test-2 ()
  (move-head-func :p-val 0 :y-val 20)
  )

(defun move-head-test-3 ()
  (move-head-look-at  (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
  )

;; move-torso primitive
(defun move-torso-test-1 ()
  (move-torso-func 325)
  )

;; move-object  primitive
(defun move-object-test-1 ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/knife-new-attention.l")
  (setq *knife* (knife))
  (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))
  
  (objects (list *scene* *pr2* *arrow* *knife*))
  (update-view)
  
  
  )
