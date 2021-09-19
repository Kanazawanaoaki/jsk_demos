#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "sato-rice-microwave-funcs.l")

(defun sato-rice-microwave-smach-test ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :recognition)
             (:recognition :success :open-microwave)
             (:open-microwave :success :put-object)
             (:put-object :success :close-microwave)
             (:close-microwave :success :push-500w-button)
             (:push-500w-button :success :push-1min-button-1)
             (:push-1min-button-1 :success :push-1min-button-2)
             (:push-1min-button-2 :success :push-start-button)
             (:push-start-button :success :wait-2min)
             (:wait-2min :success :open-microwave-2)
             (:open-microwave-2 :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             (:recognition '(lambda (&rest args) (recognition) :success))
             (:open-microwave '(lambda (&rest args) (open-microwave) :success))
             (:put-object '(lambda (&rest args) (put-object) :success))
             (:close-microwave '(lambda (&rest args) (close-microwave) :success))
             (:push-500w-button '(lambda (&rest args) (push-500w-button) :success))
             (:push-1min-button-1 '(lambda (&rest args) (push-1min-button-1) :success))
             (:push-1min-button-2 '(lambda (&rest args) (push-1min-button-2) :success))
             (:push-start-button '(lambda (&rest args) (push-start-button) :success))
             (:wait-2min '(lambda (&rest args) (wait-2min) :success))
             (:open-microwave-2 '(lambda (&rest args) (open-microwave-2) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo ()
  (ros::roseus "smach_demo")
  (exec-state-machine (sato-rice-microwave-smach-test)))

(format t ";; to run with smachk, run ~% (smach-demo) ~%")

