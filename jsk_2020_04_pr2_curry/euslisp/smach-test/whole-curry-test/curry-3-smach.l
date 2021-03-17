#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-3-funcs.l")

(defun smach-curry-3 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :grasp-onion)
             (:grasp-onion :success :move-to-sink)
             (:move-to-sink :success :wash-onion)
             (:wash-onion :success :move-to-kitchen)
             (:move-to-kitchen :success :put-onion-on-board)
             (:put-onion-on-board :success :grasp-knife)
             (:grasp-knife :success :cut-onion)
             (:cut-onion :success :put-knife)
             (:put-knife :success :transfer-to-pot)
             (:transfer-to-pot :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:grasp-onion '(lambda (&rest args) (curry-3-1) :success))
             (:move-to-sink '(lambda (&rest args) (curry-3-2) :success))
             (:wash-onion '(lambda (&rest args) (curry-3-3) :success))
             (:move-to-kitchen '(lambda (&rest args) (curry-3-4) :success))
             (:put-onion-on-board '(lambda (&rest args) (curry-3-5) :success))
             (:grasp-knife '(lambda (&rest args) (curry-3-6) :success))
             (:cut-onion '(lambda (&rest args) (curry-3-7) :success))
             (:put-knife '(lambda (&rest args) (curry-3-8) :success))
             (:transfer-to-pot '(lambda (&rest args) (curry-3-9) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-3 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-3)))

(format t ";; to run with smachk, run ~% (smach-demo-3) ~%")

