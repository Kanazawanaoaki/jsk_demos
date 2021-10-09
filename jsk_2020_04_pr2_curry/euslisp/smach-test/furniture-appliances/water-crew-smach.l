#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "water-crew-funcs.l")

(defun water-crew-smach-test ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '(
             (:init :success :off)
             (:off :finish :done)
             (:off :on :on)
             (:on :off :off)
             (:on :finish :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:off '(lambda (&rest args) (off) ))
             (:on '(lambda (&rest args) (on) ))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun water-crew-smach ()
  (ros::roseus "water-crew_smach")
  (exec-state-machine (water-crew-smach-test)))

(format t ";; to run with smachk, run ~% (water-crew-smach) ~%")

