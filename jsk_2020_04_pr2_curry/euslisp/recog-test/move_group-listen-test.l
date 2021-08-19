;; add for voice recognition

(ros::roseus "speech_rec_test" :anonymous t)
(ros::load-ros-manifest "moveit_msgs")

(defun test-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *octmap* (send (send *msg* :world) :octomap))
    (setq *octmap-data* (send (send *octmap* :octomap) :data))
    ;; (setq *data* (send *msg* :transcript))
    ;; (if (equal *data* '("OK"))
    ;;     (progn 
    ;;       (format t "了解しました！ ~%" *data*)
    ;;       )
    ;;   (format t "data: ~A ~%" *data*)
    ;;   ) 
    )
  )

(ros::unsubscribe "/move_group/monitored_planning_scene")
(setq *cb-flag* nil)
(ros::subscribe "/move_group/monitored_planning_scene" moveit_msgs::PlanningScene #'test-cb)

(defun test ()
  (do-until-key
   (ros::spin-once)
   (ros::sleep)
   )
  )

(test)


(defun one-shot-test ()
  (setq msg (one-shot-subscribe "/move_group/monitored_planning_scene" moveit_msgs::PlanningScene))
  )
