#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-5-funcs.l")

(defun smach-curry-5 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :set-fire)
             (:set-fire :success :stir-fry)
             (:stir-fry :success :turn-off-fire)
             (:turn-off-fire :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:set-fire '(lambda (&rest args) (curry-5-1) :success))
             (:stir-fry '(lambda (&rest args) (curry-5-2) :success))
             (:turn-off-fire '(lambda (&rest args) (curry-5-3) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-5 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-5)))

(format t ";; to run with smachk, run ~% (smach-demo-5) ~%")

