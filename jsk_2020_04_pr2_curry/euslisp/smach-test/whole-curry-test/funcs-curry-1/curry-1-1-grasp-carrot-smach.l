#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-1-1-grasp-carrot-funcs.l")

(defun smach-curry-1-1 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :middle-pose)
             (:middle-pose :success :grasp-carrot)
             (:grasp-carrot :success :bring-up-carrot)
             (:bring-up-carrot :success :carry-pose)
             (:carry-pose :success :done)
             (:grasp-carrot :fail :ask-for-help)
             (:ask-for-help :success :bring-up-carrot)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:middle-pose '(lambda (&rest args) (curry-1-1-1) :success))
             ;; (:grasp-carrot '(lambda (&rest args) (curry-1-1-2) (grasp-detection)))
             (:grasp-carrot '(lambda (&rest args) (curry-1-1-2) (grasp-detection-tmp)))
             (:bring-up-carrot '(lambda (&rest args) (curry-1-1-3) :success))
             (:carry-pose '(lambda (&rest args) (curry-1-1-4) :success))
             (:ask-for-help '(lambda (&rest args) (curry-1-1-2-f) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-1-1 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-1-1)))

(format t ";; to run with smachk, run ~% (smach-demo-1-1) ~%")

