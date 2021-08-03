(defun moveit-init ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  (load "package://pr2eus_moveit/euslisp/pr2eus-moveit.l")
  (send *ri* :set-moveit-environment (instance pr2-moveit-environment :init))
  )

(moveit-init)


(warn "please run (shelf-with-moveit-1) ~%")

(defun shelf-with-moveit-1 ()
  (send *arrow* :newcoords (send (car (send *shelf-door* :handle)) :copy-worldcoords))
  
  (send *arrow* :translate (float-vector 100 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector-motion-plan (send *pr2* :angle-vector) :total-time 5000 :ctype :rarm-controller :start-offset-time 0 :move-arm :rarm)
  (send *ri* :wait-interpolation)
  
  (warn "please run (shelf-with-moveit-2) ~%")
  )

(defun shelf-with-moveit-2 ()
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  ;; ノブのところまで手を伸ばす 力覚を入れても良い．
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 10)
    (send *arrow* :translate (float-vector -10 0 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.01))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe "/right_endeffector/wrench")
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(10 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :rarm :wait t)
  (send *ri* :start-grasp :rarm :wait t :gain 0.08)
  
  (set-shelf-door)
  (warn "please run (open-shelf) ~%")
  )


(defun shelf-pos-1-irt ()
  (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)
  )

(defun shelf-pos-2-irt ()
  (setq *shelf-spot-tmp* (make-coords :pos (float-vector 1100.0 8500.0 30000.0) :rpy (float-vector 3.142 0.0 0.0)))
  (send *pr2* :move-to (send *shelf-spot-tmp* :copy-worldcoords) :world)
  
  )


(defun ik-check ()
  (now-set-in-shelf)
  )
