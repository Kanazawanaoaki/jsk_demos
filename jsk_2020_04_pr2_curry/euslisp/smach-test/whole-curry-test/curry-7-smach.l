#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-7-funcs.l")

(defun smach-curry-7 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :move-to-kitchen)
             (:move-to-kitchen :success :transfer-to-pot)
             (:transfer-to-pot :success :grasp-mcup)
             (:grasp-mcup :success :fetch-water)
             (:fetch-water :success :put-mcup)
             (:put-mcup :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:move-to-kitchen '(lambda (&rest args) (curry-7-1) :success))
             (:transfer-to-pot '(lambda (&rest args) (curry-7-2) :success))
             (:grasp-mcup '(lambda (&rest args) (curry-7-3) :success))
             (:fetch-water '(lambda (&rest args) (curry-7-4) :success))
             (:put-mcup '(lambda (&rest args) (curry-7-5) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-7 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-7)))

(format t ";; to run with smachk, run ~% (smach-demo-7) ~%")

