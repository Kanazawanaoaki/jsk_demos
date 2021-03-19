#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-7-4-fetch-water-funcs.l")

(defun smach-curry-7-4 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :move-to-sink)
             (:move-to-sink :success :fetch-water)
             (:fetch-water :success :move-to-kitchen)
             (:move-to-kitchen :success :pour-water)
             (:pour-water :success :check-water-state)
             (:check-water-state :success :done)
             (:check-water-state :fail :move-to-sink)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:move-to-sink '(lambda (&rest args) (curry-7-4-1) :success))
             (:fetch-water '(lambda (&rest args) (curry-7-4-2) :success))
             (:move-to-kitchen '(lambda (&rest args) (curry-7-4-3) :success))
             (:pour-water '(lambda (&rest args) (curry-7-4-4) :success))
             ;; (:check-water-state '(lambda (&rest args) (curry-7-4-5) (check-water-state-func)))
             (:check-water-state '(lambda (&rest args) (curry-7-4-5) (check-water-state-func-tmp)))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-7-4 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-7-4)))

(format t ";; to run with smachk, run ~% (smach-demo-7-4) ~%")

