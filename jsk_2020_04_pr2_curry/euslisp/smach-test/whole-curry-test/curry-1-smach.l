#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-1-funcs.l")

(defun smach-curry-1 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :grasp-carrot)
             (:grasp-carrot :success :move-to-sink)
             (:move-to-sink :success :wash-carrot)
             (:wash-carrot :success :move-to-kitchen)
             (:move-to-kitchen :success :put-carrot-on-board)
             (:put-carrot-on-board :success :grasp-peeler)
             (:grasp-peeler :success :peel-carrot)
             (:peel-carrot :success :replace-tool)
             (:replace-tool :success :cut-carrot)
             (:cut-carrot :success :put-knife)
             (:put-knife :success :transfer-to-bowl-1)
             (:transfer-to-bowl-1 :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:grasp-carrot '(lambda (&rest args) (curry-1-1) :success))
             (:move-to-sink '(lambda (&rest args) (curry-1-2) :success))
             (:wash-carrot '(lambda (&rest args) (curry-1-3) :success))
             (:move-to-kitchen '(lambda (&rest args) (curry-1-4) :success))
             (:put-carrot-on-board '(lambda (&rest args) (curry-1-5) :success))
             (:grasp-peeler '(lambda (&rest args) (curry-1-6) :success))
             (:peel-carrot '(lambda (&rest args) (curry-1-7) :success))
             (:replace-tool '(lambda (&rest args) (curry-1-8) :success))
             (:cut-carrot '(lambda (&rest args) (curry-1-9) :success))
             (:put-knife '(lambda (&rest args) (curry-1-10) :success))
             (:transfer-to-bowl-1 '(lambda (&rest args) (curry-1-11) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-1 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-1)))

(format t ";; to run with smachk, run ~% (smach-demo-1) ~%")

