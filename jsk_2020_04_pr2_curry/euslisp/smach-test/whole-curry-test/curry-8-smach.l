#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-8-funcs.l")

(defun smach-curry-8 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :set-fire)
             (:set-fire :success :boil)
             (:boil :success :adjust-fire)
             (:adjust-fire :success :stew)
             (:stew :success :turn-off-fire)
             (:turn-off-fire :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:set-fire '(lambda (&rest args) (curry-8-1) :success))
             (:boil '(lambda (&rest args) (curry-8-2) :success))
             (:adjust-fire '(lambda (&rest args) (curry-8-3) :success))
             (:stew '(lambda (&rest args) (curry-8-4) :success))
             (:turn-off-fire '(lambda (&rest args) (curry-8-5) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-8 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-8)))

(format t ";; to run with smachk, run ~% (smach-demo-8) ~%")

