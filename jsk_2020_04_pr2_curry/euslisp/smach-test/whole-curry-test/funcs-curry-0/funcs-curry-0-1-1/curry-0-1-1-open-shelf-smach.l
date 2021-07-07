#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-0-1-1-open-shelf-funcs.l")

(defun smach-curry-0-1-1 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :look-at-shelf)
             (:look-at-shelf :success :grasp-handle)
             (:grasp-handle :success :open-door)
             (:open-door :success :done)
             (:grasp-handle :fail :ask-for-help)
             (:ask-for-help :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:look-at-shelf '(lambda (&rest args) (curry-0-1-1-1) :success))
             ;; (:grasp-handle '(lambda (&rest args) (curry-0-1-1-2) (grasp-detection)))
             (:grasp-handle '(lambda (&rest args) (curry-0-1-1-2) (grasp-detection-tmp)))
             (:open-door '(lambda (&rest args) (curry-0-1-1-3) :success))
             (:ask-for-help '(lambda (&rest args) (curry-0-1-1-2-f) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-0-1-1 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-0-1-1)))

(format t ";; to run with smachk, run ~% (smach-demo-0-1-1) ~%")

