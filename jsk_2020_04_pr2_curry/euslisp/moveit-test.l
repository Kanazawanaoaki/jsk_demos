(load "package://pr2eus/pr2-interface.l")
(load "package://pr2eus_moveit/euslisp/pr2eus-moveit.l")
(pr2-init)

(load "models/arrow-object.l")
(setq *arrow* (arrow))

(objects (list *pr2* *arrow*))

(send *pr2* :reset-pose)
(send *ri* :angle-vector (send *pr2* :angle-vector) 5000)

(send *arrow* :newcoords (make-coords :pos #f(800 400 1000)))

(defun normal-ik ()
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  )

(defun moveit-ik ()
  ;;(send ri :set-moveit-environment (instance pr2-moveit-environment :init)) ;;多分不要
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *ri* :angle-vector-motion-plan (send *pr2* :angle-vector) :total-time 5000 :ctype :larm-controller :start-offset-time 0 :move-arm :larm)
  )

(warn "please use (normal-ik) or (moveit-ik)~%")
