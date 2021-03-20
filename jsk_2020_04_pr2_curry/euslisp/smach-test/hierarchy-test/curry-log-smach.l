#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-log-funcs.l")

(defun smach-curry-test ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :preparation)
             (:preparation :success :carrot-preparation)
             (:carrot-preparation :success :potato-preparation)
             (:potato-preparation :success :onion-preparation)
             (:onion-preparation :success :fry-preparation)
             (:fry-preparation :success :fry-onion)
             (:fry-onion :success :fry-meat)
             (:fry-meat :success :stew-preparation)
             (:stew-preparation :success :stew)
             (:stew :success :curry-roux)
             (:curry-roux :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:preparation '(lambda (&rest args) (curry-0) :success))
             (:carrot-preparation '(lambda (&rest args) (curry-1) :success))
             (:potato-preparation '(lambda (&rest args) (curry-2) :success))
             (:onion-preparation '(lambda (&rest args) (curry-3) :success))
             (:fry-preparation '(lambda (&rest args) (curry-4) :success))
             (:fry-onion '(lambda (&rest args) (curry-5) :success))
             (:fry-meat '(lambda (&rest args) (curry-6) :success))
             (:stew-preparation '(lambda (&rest args) (curry-7) :success))
             (:stew '(lambda (&rest args) (curry-8) :success))
             (:curry-roux '(lambda (&rest args) (curry-9) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-test)))

(format t ";; to run with smachk, run ~% (smach-demo) ~%")

