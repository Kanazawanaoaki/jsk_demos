#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/easy-microwave-funcs.l")

(defun microwave-smach-test ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '(
             (:init :success :off)
             
             (:off :finish :done)
             (:off :open :open)
             (:open :close :0s)

             (:0s :finish :done)
             (:0s :off :off)
             (:0s :500w :500w)
             (:0s :open :open)

             (:500w :1min :1min)
             (:500w :open :open)

             (:1min :2min :2min)
             (:1min :heating :heating)
             (:1min :open :open)
             
             (:2min :3min :3min)
             (:2min :heating :heating)
             (:2min :open :open)

             (:3min :heating :heating)
             (:3min :open :open)

             (:heating :time-elapsed :0s)
             
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:off '(lambda (&rest args) (off) ))
             (:open '(lambda (&rest args) (open) ))
             (:0s '(lambda (&rest args) (0s) ))
             (:500w '(lambda (&rest args) (500w) ))
             (:1min '(lambda (&rest args) (1min) ))
             (:2min '(lambda (&rest args) (2min) ))
             (:3min '(lambda (&rest args) (3min) ))
             (:heating '(lambda (&rest args) (heating) ))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun microwave-smach ()
  (ros::roseus "microwave_smach")
  (exec-state-machine (microwave-smach-test)))

(format t ";; to run with smachk, run ~% (microwave-smach) ~%")

