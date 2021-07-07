#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-1-7-1-peel-half-funcs.l")

(defun smach-curry-1-7-1 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :grasp-carrot)
             (:grasp-carrot :success :set-carrot-peel)
             (:set-carrot-peel :success :peel)
             (:peel :success :reset-rarm)
             (:reset-rarm :success :put-carrot)
             (:put-carrot :success :done)

             (:grasp-carrot :fail :reset-arm)
             (:set-carrot-peel :fail :reset-arm)
             (:reset-arm :success :reset-carrot)
             (:reset-carrot :success :done)
             
             (:peel :fail :set-carrot-peel)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             ;; (:grasp-carrot '(lambda (&rest args) (curry-1-7-1-1) (grasp-detection)))
             (:grasp-carrot '(lambda (&rest args) (curry-1-7-1-1) (grasp-detection-tmp)))             
             ;; (:set-carrot-peel '(lambda (&rest args) (curry-1-7-1-2) (grasp-detection)))
             (:set-carrot-peel '(lambda (&rest args) (curry-1-7-1-2) (grasp-detection-tmp)))
             
             (:peel '(lambda (&rest args) (curry-1-7-1-3) (if (< (incf count) 7) :fail :success)))
             (:reset-rarm '(lambda (&rest args) (curry-1-7-1-4) :success))
             (:put-carrot '(lambda (&rest args) (curry-1-7-1-5) :success))
             
             (:reset-arm '(lambda (&rest args) (curry-1-7-1-f-1) :success))
             (:reset-carrot '(lambda (&rest args) (curry-1-7-1-f-2) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-1-7-1 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-1-7-1)))

(format t ";; to run with smachk, run ~% (smach-demo-1-7-1) ~%")

