#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-5-2-set-fire-funcs.l")

(defun smach-curry-5-2 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :push-knob)
             (:push-knob :success :grasp-knob)
             (:grasp-knob :success :rotate-knob)
             (:rotate-knob :success :release-knob)
             (:release-knob :success :done)
             (:grasp-knob :fail :ask-for-help)
             (:ask-for-help :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:push-knob '(lambda (&rest args) (curry-5-2-1) :success))
             ;; (:grasp-knob '(lambda (&rest args) (curry-5-2-2) (grasp-detection)))
             (:grasp-knob '(lambda (&rest args) (curry-5-2-2) (grasp-detection-tmp)))
             (:rotate-knob '(lambda (&rest args) (curry-5-2-3) :success))
             (:release-knob '(lambda (&rest args) (curry-5-2-4) :success))
             (:ask-for-help '(lambda (&rest args) (curry-5-2-2-f) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-5-2 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-5-2)))

(format t ";; to run with smachk, run ~% (smach-demo-5-2) ~%")

