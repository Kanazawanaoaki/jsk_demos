#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-4-funcs.l")

(defun smach-curry-4 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :set-from-shelf)
             (:set-from-shelf :success :move-to-stove)
             (:move-to-stove :success :add-oil)
             (:add-oil :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:set-from-shelf '(lambda (&rest args) (curry-4-1) :success))
             (:move-to-stove '(lambda (&rest args) (curry-4-2) :success))
             (:add-oil '(lambda (&rest args) (curry-4-3) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-4 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-4)))

(format t ";; to run with smachk, run ~% (smach-demo-4) ~%")

