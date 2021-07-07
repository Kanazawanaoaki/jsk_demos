#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-0-funcs.l")

(defun smach-curry-0 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :set-in-shelf)
             (:set-in-shelf :success :set-bowl-1)
             (:set-bowl-1 :success :set-vegs)
             (:set-vegs :success :set-mcup)
             (:set-mcup :success :move-to-stove)
             (:move-to-stove :success :set-bowl-2-3)
             (:set-bowl-2-3 :success :move-to-kitchen)
             (:move-to-kitchen :success :set-board)
             (:set-board :success :set-tools-on-table)
             (:set-tools-on-table :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:set-in-shelf '(lambda (&rest args) (curry-0-1) :success))
             (:set-bowl-1 '(lambda (&rest args) (curry-0-2) :success))
             (:set-vegs '(lambda (&rest args) (curry-0-3) :success))
             (:set-mcup '(lambda (&rest args) (curry-0-4) :success))
             (:move-to-stove '(lambda (&rest args) (curry-0-5) :success))
             (:set-bowl-2-3 '(lambda (&rest args) (curry-0-6) :success))
             (:move-to-kitchen '(lambda (&rest args) (curry-0-7) :success))
             (:set-board '(lambda (&rest args) (curry-0-8) :success))
             (:set-tools-on-table '(lambda (&rest args) (curry-0-9) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-0 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-0)))

(format t ";; to run with smachk, run ~% (smach-demo-0) ~%")

