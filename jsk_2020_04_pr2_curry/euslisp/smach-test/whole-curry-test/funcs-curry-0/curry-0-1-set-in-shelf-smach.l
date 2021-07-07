#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-0-1-grasp-carrot-funcs.l")

(defun smach-curry-0-1 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :open-shelf)
             (:open-shelf :success :set-spatula-in-shelf)
             (:set-spatula-in-shelf :success :set-ladle-in-shelf)
             (:set-ladle-in-shelf :success :close-shelf)
             (:close-shelf :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:open-shelf '(lambda (&rest args) (curry-0-1-1) :success))
             (:set-spatula-in-shelf '(lambda (&rest args) (curry-0-1-2) :success))
             (:set-ladle-in-shelf '(lambda (&rest args) (curry-0-1-3) :success))
             (:close-shelf '(lambda (&rest args) (curry-0-1-4) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-0-1 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-0-1)))

(format t ";; to run with smachk, run ~% (smach-demo-0-1) ~%")

