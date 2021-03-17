#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-2-funcs.l")

(defun smach-curry-2 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :grasp-potato)
             (:grasp-potato :success :move-to-sink)
             (:move-to-sink :success :wash-potato)
             (:wash-potato :success :move-to-kitchen)
             (:move-to-kitchen :success :put-potato-on-board)
             (:put-potato-on-board :success :grasp-potato-peeler)
             (:grasp-potato-peeler :success :peel-potato)
             (:peel-potato :success :replace-tool)
             (:replace-tool :success :cut-potato)
             (:cut-potato :success :put-knife)
             (:put-knife :success :transfer-to-bowl-1)
             (:transfer-to-bowl-1 :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:grasp-potato '(lambda (&rest args) (curry-2-1) :success))
             (:move-to-sink '(lambda (&rest args) (curry-2-2) :success))
             (:wash-potato '(lambda (&rest args) (curry-2-3) :success))
             (:move-to-kitchen '(lambda (&rest args) (curry-2-4) :success))
             (:put-potato-on-board '(lambda (&rest args) (curry-2-5) :success))
             (:grasp-potato-peeler '(lambda (&rest args) (curry-2-6) :success))
             (:peel-potato '(lambda (&rest args) (curry-2-7) :success))
             (:replace-tool '(lambda (&rest args) (curry-2-8) :success))
             (:cut-potato '(lambda (&rest args) (curry-2-9) :success))
             (:put-knife '(lambda (&rest args) (curry-2-10) :success))
             (:transfer-to-bowl-1 '(lambda (&rest args) (curry-2-11) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-2 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-2)))

(format t ";; to run with smachk, run ~% (smach-demo-2) ~%")

