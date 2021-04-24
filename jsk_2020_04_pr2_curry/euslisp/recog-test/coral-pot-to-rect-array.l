#!/usr/bin/env roseus


(ros::roseus "coral_pot_to_rect_array_test" :anonymous t)
(ros::load-ros-package "jsk_recognition_msgs")

(setq *target-label-num* 11) ;; 11 pot 
(setq *target-label-name* "pot") ;; 11 pot 

(setq *class-msg* "/edgetpu_object_detector/output/class")
(setq *rects-msg* "/edgetpu_object_detector/output/rects")
(setq *pub-msg* "/coral_pot_to_rect_array/output")

(defun class-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq name-lists (send msg :label_names))
    (print name-lists)
    (dotimes (i (length name-lists)) ;; 現状２つ認識された時のことを考えていない
      (if (equal *target-label-name* (elt name-lists i))
          (progn
            (setq *target-label-index* i)
            (format t "target index is ~A ~%" i)
            )
        )
      )
    ))


(ros::unsubscribe *class-msg*)
(setq *cb-flag* nil)
(ros::subscribe *class-msg* jsk_recognition_msgs::ClassificationResult #'class-cb)

(defun test ()
  (do-until-key
   (ros::spin-once)
   (ros::sleep)
   )
  )

(test)

