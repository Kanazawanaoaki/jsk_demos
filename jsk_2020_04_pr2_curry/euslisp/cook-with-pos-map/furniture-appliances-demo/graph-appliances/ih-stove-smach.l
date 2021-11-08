#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/easy-ver-ih-stove-funcs.l")

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
             (:off :push-knob :on)
             (:on :push-knob :off)
             ;; (:on :finish :done)

             (:on :rotate-knob :medium-heat)

             (:melting-fire :push-knob :off)
             (:low-heat :push-knob :off)
             (:medium-heat :push-knob :off)
             (:high-heat :push-knob :off)
             (:high-power :push-knob :off)

             (:melting-fire :rotate-knob-right :low-heat)

             (:low-heat :rotate-knob-left :melting-fire)
             (:low-heat :rotate-knob-right :medium-heat)
             
             (:medium-heat :rotate-knob-left :low-heat)
             (:medium-heat :rotate-knob-right :high-heat)

             (:high-heat :rotate-knob-left :medium-heat)
             (:high-heat :rotate-knob-right :high-power)

             (:high-power :rotate-knob-left :high-heat)
             
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

