#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-1-7-peel-carrot-funcs.l")

(defun smach-curry-1-7 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :peel-half)
             (:peel-half :success :rotate-carrot)
             (:rotate-carrot :success :peel-rest)
             (:peel-rest :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:peel-half '(lambda (&rest args) (curry-1-7-1) :success))
             (:rotate-carrot '(lambda (&rest args) (curry-1-7-2) :success))
             (:peel-rest '(lambda (&rest args) (curry-1-7-3) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-1-7 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-1-7)))

(format t ";; to run with smachk, run ~% (smach-demo-1-7) ~%")

