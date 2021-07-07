#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-6-funcs.l")

(defun smach-curry-6 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :transfer-to-pot)
             (:transfer-to-pot :success :set-fire)
             (:set-fire :success :stir-fry)
             (:stir-fry :success :turn-off-fire)
             (:turn-off-fire :success :put-spatula)
             (:put-spatula :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:transfer-to-pot '(lambda (&rest args) (curry-6-1) :success))
             (:set-fire '(lambda (&rest args) (curry-6-2) :success))
             (:stir-fry '(lambda (&rest args) (curry-6-3) :success))
             (:turn-off-fire '(lambda (&rest args) (curry-6-4) :success))
             (:put-spatula '(lambda (&rest args) (curry-6-5) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-6 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-6)))

(format t ";; to run with smachk, run ~% (smach-demo-6) ~%")

