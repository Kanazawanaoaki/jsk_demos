#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-log-test.l")


(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun smach-curry-test ()
  (let (sm)
    (setq count 0) ;; 失敗した数を数える．
    (setq sm
          (make-state-machine
           ;; define graph,  list of (<from-node> <transition> <to-node>)
           ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
           '((:init :success :preparation)
             (:preparation :success :carrot-preparation)
             (:preparation :fail :preparation-recovery)
             (:preparation-recovery :success :carrot-preparation)

             (:carrot-preparation :success :potato-preparation)
             (:carrot-preparation :fail :carrot-preparation-recovery)
             (:carrot-preparation-recovery :success :potato-preparation)
             
             (:potato-preparation :success :onion-preparation)
             (:potato-preparation :fail :potato-preparation-recovery)
             (:potato-preparation-recovery :success :onion-preparation)
             
             (:onion-preparation :success :fry-preparation)
             (:onion-preparation :fail :onion-preparation-recovery)
             (:onion-preparation-recovery :success :fry-preparation)
             
             (:fry-preparation :success :fry-onion)
             (:fry-preparation :fail :fry-preparation-recovery)
             (:fry-preparation-recovery :success :fry-onion)
             
             (:fry-onion :success :fry-meat)
             (:fry-onion :fail :fry-onion-recovery)
             (:fry-onion-recovery :success :fry-meat)
             
             (:fry-meat :success :stew-preparation)
             (:fry-meat :fail :fry-meat-recovery)
             (:fry-meat-recovery :success :stew-preparation)             
             
             (:stew-preparation :success :stew)
             (:stew-preparation :fail :stew-preparation-recovery)
             (:stew-preparation-recovery :success :stew)

             (:stew :success :curry-roux)
             (:stew :fail :stew-recovery)
             (:stew-recovery :success :curry-roux)
             
             (:curry-roux :success :done)
             (:curry-roux :fail :curry-roux-recovery)
             (:curry-roux-recovery :success :done)
             )
           ;; define function map
           '((:init '(lambda (&rest args) (init) :success))
             ;; (:preparation '(lambda (&rest args) (curry-0) :success))
             ;; (:carrot-preparation '(lambda (&rest args) (curry-1) :success))
             ;; (:potato-preparation '(lambda (&rest args) (curry-2) :success))
             ;; (:onion-preparation '(lambda (&rest args) (curry-3) :success))
             ;; (:fry-preparation '(lambda (&rest args) (curry-4) :success))
             ;; (:fry-onion '(lambda (&rest args) (curry-5) :success))
             ;; (:fry-meat '(lambda (&rest args) (curry-6) :success))
             ;; (:stew-preparation '(lambda (&rest args) (curry-7) :success))
             ;; (:stew '(lambda (&rest args) (curry-8) :success))
             ;; (:curry-roux '(lambda (&rest args) (curry-9) :success))

             (:preparation '(lambda (&rest args) (curry-0) (curry-state-ask)))
             (:carrot-preparation '(lambda (&rest args) (curry-1) (curry-state-ask)))
             (:potato-preparation '(lambda (&rest args) (curry-2) (curry-state-ask)))
             (:onion-preparation '(lambda (&rest args) (curry-3) (curry-state-ask)))
             (:fry-preparation '(lambda (&rest args) (curry-4) (curry-state-ask)))
             (:fry-onion '(lambda (&rest args) (curry-5) (curry-state-ask)))
             (:fry-meat '(lambda (&rest args) (curry-6) (curry-state-ask)))
             (:stew-preparation '(lambda (&rest args) (curry-7) (curry-state-ask)))
             (:stew '(lambda (&rest args) (curry-8) (curry-state-ask)))
             (:curry-roux '(lambda (&rest args) (curry-9) (curry-state-ask)))

             (:preparation-recovery '(lambda (&rest args) (curry-0-recovery) :success))
             (:carrot-preparation-recovery '(lambda (&rest args) (curry-1-recovery) :success))
             (:potato-preparation-recovery '(lambda (&rest args) (curry-2-recovery) :success))
             (:onion-preparation-recovery '(lambda (&rest args) (curry-3-recovery) :success))
             (:fry-preparation-recovery '(lambda (&rest args) (curry-4-recovery) :success))
             (:fry-onion-recovery '(lambda (&rest args) (curry-5-recovery) :success))
             (:fry-meat-recovery '(lambda (&rest args) (curry-6-recovery) :success))
             (:stew-preparation-recovery '(lambda (&rest args) (curry-7-recovery) :success))
             (:stew-recovery '(lambda (&rest args) (curry-8-recovery) :success))
             (:curry-roux-recovery '(lambda (&rest args) (curry-9-recovery) :success))
             )
           ;; initial state
           '(:init)
           ;; goal state
           '(:done)))))

(defun smach-demo ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-test)))

(format t ";; to run with smachk, run ~% (smach-demo) ~%")

