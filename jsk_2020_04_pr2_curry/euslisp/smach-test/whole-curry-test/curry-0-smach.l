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
             (:set-bowl-1 :success :potato-set-in-shelf) ;; TODO ここから．
             (:potato-set-in-shelf :success :onion-set-in-shelf)
             (:onion-set-in-shelf :success :fry-set-in-shelf)
             (:fry-set-in-shelf :success :fry-onion)
             (:fry-onion :success :fry-meat)
             (:fry-meat :success :stew-set-in-shelf)
             (:stew-set-in-shelf :success :stew)
             (:stew :success :curry-roux)
             (:curry-roux :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:set-in-shelf '(lambda (&rest args) (curry-0-1) :success))
             (:set-bowl-1 '(lambda (&rest args) (curry-0-2) :success))
             (:potato-set-in-shelf '(lambda (&rest args) (curry-0-3) :success))
             (:onion-set-in-shelf '(lambda (&rest args) (curry-0-4) :success))
             (:fry-set-in-shelf '(lambda (&rest args) (curry-0-5) :success))
             (:fry-onion '(lambda (&rest args) (curry-0-6) :success))
             (:fry-meat '(lambda (&rest args) (curry-0-7) :success))
             (:stew-set-in-shelf '(lambda (&rest args) (curry-0-8) :success))
             (:stew '(lambda (&rest args) (curry-0-9) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-0 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-0)))

(format t ";; to run with smachk, run ~% (smach-demo) ~%")

