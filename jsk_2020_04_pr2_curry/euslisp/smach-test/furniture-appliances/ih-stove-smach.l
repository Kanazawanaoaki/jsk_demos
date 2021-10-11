#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "ih-stove-funcs.l")

(defun ih-stove-smach-test ()
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

             (:on :melting-fire :melting-fire)
             (:on :low-heat :low-heat)
             (:on :medium-heat :medium-heat)
             (:on :high-heat :high-heat)
             (:on :high-power :high-power)

             (:melting-fire :off :off)
             (:low-heat :off :off)
             (:medium-heat :off :off)
             (:high-heat :off :off)
             (:high-power :off :off)

             (:melting-fire :low-heat :low-heat)
             (:melting-fire :medium-heat :medium-heat)
             (:melting-fire :high-heat :high-heat)
             (:melting-fire :high-power :high-power)

             (:low-heat :melting-fire :melting-fire)
             (:low-heat :medium-heat :medium-heat)
             (:low-heat :high-heat :high-heat)
             (:low-heat :high-power :high-power)
             
             (:medium-heat :melting-fire :melting-fire)
             (:medium-heat :low-heat :low-heat)
             (:medium-heat :high-heat :high-heat)
             (:medium-heat :high-power :high-power)

             (:high-heat :melting-fire :melting-fire)
             (:high-heat :low-heat :low-heat)
             (:high-heat :medium-heat :medium-heat)
             (:high-heat :high-power :high-power)

             (:high-power :melting-fire :melting-fire)
             (:high-power :low-heat :low-heat)
             (:high-power :medium-heat :medium-heat)
             (:high-power :high-heat :high-heat)
             
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:off '(lambda (&rest args) (off) ))
             (:on '(lambda (&rest args) (on) ))
             (:melting-fire '(lambda (&rest args) (melting-fire) ))
             (:low-heat '(lambda (&rest args) (low-heat) ))
             (:medium-heat '(lambda (&rest args) (medium-heat) ))
             (:high-heat '(lambda (&rest args) (high-heat) ))
             (:high-power '(lambda (&rest args) (high-power) ))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun ih-stove-smach ()
  (ros::roseus "ih-stove_smach")
  (exec-state-machine (ih-stove-smach-test)))

(format t ";; to run with smachk, run ~% (ih-stove-smach) ~%")

