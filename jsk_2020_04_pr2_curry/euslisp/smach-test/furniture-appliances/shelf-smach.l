#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "shelf-funcs.l")

(defun shelf-smach-test ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '(
             (:init :success :close)
             (:close :success :done)
             (:close :open :open)
             (:open :close :close)
             (:open :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:close '(lambda (&rest args) (close) :success))
             (:open '(lambda (&rest args) (open) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun shelf-smach ()
  (ros::roseus "shelf_smach")
  (exec-state-machine (shelf-smach-test)))

(format t ";; to run with smachk, run ~% (shelf-smach) ~%")

