#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-9-funcs.l")

(defun smach-curry-9 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :transfer-to-pot)
             (:transfer-to-pot :success :put-spatula)
             (:put-spatula :success :set-fire)
             (:set-fire :success :stew)
             (:stew :success :turn-off-fire)
             (:turn-off-fire :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:transfer-to-pot '(lambda (&rest args) (curry-9-1) :success))
             (:put-spatula '(lambda (&rest args) (curry-9-2) :success))
             (:set-fire '(lambda (&rest args) (curry-9-3) :success))
             (:stew '(lambda (&rest args) (curry-9-4) :success))
             (:turn-off-fire '(lambda (&rest args) (curry-9-5) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-9 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-9)))

(format t ";; to run with smachk, run ~% (smach-demo-9) ~%")

