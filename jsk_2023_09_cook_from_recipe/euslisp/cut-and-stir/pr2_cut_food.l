#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; global variables


;; defun action codes
(defun change-hsi-param (&key (object-name "knife"))
  (cond
   ((string= object-name "knife")
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_max" :int 127)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_min" :int 58)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_max" :int 15)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_min" :int 0)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_max" :int 52)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_min" :int 16)
    )
   ((string= object-name "board")
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_max" :int -93)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_min" :int -128)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_max" :int 28)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_min" :int 0)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_max" :int 255)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_min" :int 209)
    )
   )
  (format t "change hsi param to ~A detection ~%" object-name)
  t)

(defun change-deva-param (&key (object-name "knife"))
  (cond
   ((string= object-name "knife")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "knife;")
    )
   ((string= object-name "board")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "white board;")
    )
   )
  (format t "change hsi param to ~A detection ~%" object-name)
  t)
