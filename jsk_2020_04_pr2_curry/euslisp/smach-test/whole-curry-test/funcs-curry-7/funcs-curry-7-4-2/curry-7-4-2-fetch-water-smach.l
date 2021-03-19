#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-7-4-2-fetch-water-funcs.l")

(defun smach-curry-7-4-2 ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :set-mcup)
             (:set-mcup :success :grasp-rever)
             (:grasp-rever :success :water-on)
             (:water-on :success :water-stop)
             (:water-stop :success :carry-pose)
             (:carry-pose :success :done)

             (:grasp-rever :fail :grasp-rever-slide)
             (:grasp-rever-slide :success :water-on)
             (:grasp-rever-slide :fail :ask-for-help)
             (:ask-for-help :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:set-mcup '(lambda (&rest args) (curry-7-4-2-1) :success))
             ;; (:grasp-rever '(lambda (&rest args) (curry-7-4-2-2) (grasp-detection)))
             (:grasp-rever '(lambda (&rest args) (curry-7-4-2-2) (grasp-detection-tmp)))
             (:water-on '(lambda (&rest args) (curry-7-4-2-3) :success))
             (:water-stop '(lambda (&rest args) (curry-7-4-2-4) :success))
             (:carry-pose '(lambda (&rest args) (curry-7-4-2-5) :success))
             (:grasp-rever-slide '(lambda (&rest args) (curry-7-4-2-2-f-1) (grasp-detection-tmp)))
             (:ask-for-help '(lambda (&rest args) (curry-7-4-2-2-f-2) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo-7-4-2 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-7-4-2)))

(format t ";; to run with smachk, run ~% (smach-demo-7-4-2) ~%")

