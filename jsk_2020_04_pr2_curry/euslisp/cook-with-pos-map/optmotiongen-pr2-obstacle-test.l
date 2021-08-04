(load "package://eus_qp/optmotiongen/euslisp/inverse-kinematics-wrapper.l")
(load "package://eus_qp/optmotiongen/euslisp/discrete-kinematics-configuration-task.l")
(load "package://eus_qp/optmotiongen/euslisp/sqp-msc-optimization.l")
(require "irteus/demo/sample-arm-model.l")
(require "package://pr2eus/pr2.l")
(require "models/arrow-object.l")

(setq irteus-ik? nil)

(setq *robot* (instance pr2-robot :init))
(setq *arrow* (instance arrow-object :init))
(send *arrow* :newcoords
      (make-coords :pos (float-vector  550 50 600) :rpy (list (deg2rad 60) 0 0)))
(setq *obstacle* (make-cube 250 250 250))
(send *obstacle* :newcoords
      (make-coords :pos (float-vector 500 -200 700)))
(send *obstacle* :set-color (float-vector 1 0 0) 0.5)
(objects (list *robot* *arrow* *obstacle*))


(warn "please run (normal-ik) or (obstacle-ik)~%")

(defun normal-ik ()
  (send *robot* :reset-pose)
  (send *robot* :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :link-list (send *robot* :link-list (send (send *robot* :rarm :end-coords) :parent))
        :move-target (send *robot* :rarm :end-coords)
        :rotation-axis nil
        :debug-view t
        )
  (warn "please run (normal-ik) or (obstacle-ik)~%")
  )
(defun obstacle-ik ()
  (send *robot* :reset-pose)
  (send *robot*
        :inverse-kinematics-optmotiongen
        (send *arrow* :copy-worldcoords)
        :link-list (send *robot* :link-list (send (send *robot* :rarm :end-coords) :parent))
        :move-target (send *robot* :rarm :end-coords)
        :translation-axis t
        :rotation-axis nil
        :debug-view t
        :collision-avoidance-link-pair (mapcar #'(lambda (l) (list l *obstacle*)) (append (send *robot* :link-list (send *robot* :rarm :end-coords :parent)) (list (send *robot* :r_forearm_link_lk) (send *robot* :r_upper_arm_link_lk) (send *robot* :r_gripper_palm_link_lk) (send *robot* :r_gripper_r_finger_link_lk) (send *robot* :r_gripper_l_finger_link_lk) (send *robot* :r_gripper_r_finger_tip_link_lk) (send *robot* :r_gripper_l_finger_tip_link_lk))))
        )
  (warn "please run (normal-ik) or (obstacle-ik)~%")
  )
