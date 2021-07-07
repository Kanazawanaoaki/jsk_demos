#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-1-7-peel-carrot-nest-funcs.l")

(defun smach-curry-1-7 ()
  (let ((sm-top (instance state-machine :init))
	(sm-sub (instance state-machine :init)))
    ;; state instance can include other state-machine like function
    (send sm-top :add-node (instance state :init "PEEL-HALF" sm-sub))
    ;; (send sm-top :add-node (instance state :init "PEEL-HALF" '(lambda (&rest args) (curry-1-7-1) :success)))
    (send sm-top :add-node (instance state :init "ROTATE-CARROT" '(lambda (&rest args) (curry-1-7-2) :success)))
    (send sm-top :add-node (instance state :init "PEEL-REST" '(lambda (&rest args) (curry-1-7-3) :success)))
    (send sm-top :goal-state :done)
    (send sm-top :start-state "PEEL-HALF")
    (send sm-top :add-transition "PEEL-HALF" "ROTATE-CARROT" :success)
    (send sm-top :add-transition "ROTATE-CARROT" "PEEL-REST" :success)
    (send sm-top :add-transition "PEEL-REST" :done :success)

    ;; node instance can be args of :add-node, :start-state, :add-transition
    (let ((grasp-carrot-node (instance state :init "GRASP-CARROT" '(lambda (&rest args) (curry-1-7-1-1) (setq count 0) (grasp-detection-tmp))))
          (set-carrot-peel-node (instance state :init "SET-CARROT-PEEL" '(lambda (&rest args) (curry-1-7-1-2) (grasp-detection-tmp))))
          (peel-node (instance state :init "PEEL" '(lambda (&rest args) (curry-1-7-1-3) (if (< (incf count) 7) :fail :success))))
          (reset-rarm-node (instance state :init "RESET-RARM" '(lambda (&rest args) (curry-1-7-1-4) :success)))
          (put-carrot-node (instance state :init "PUT-CARROT" '(lambda (&rest args) (curry-1-7-1-5) :success)))
          
          (reset-arm-node (instance state :init "RESET-ARM" '(lambda (&rest args) (curry-1-7-1-f-1) :success)))
          (reset-carrot-node (instance state :init "RESET-CARROT" '(lambda (&rest args) (curry-1-7-1-f-2) :success)))
          )
      (send sm-sub :add-node grasp-carrot-node)
      (send sm-sub :add-node set-carrot-peel-node)
      (send sm-sub :add-node peel-node)
      (send sm-sub :add-node reset-rarm-node)
      (send sm-sub :add-node put-carrot-node)

      (send sm-sub :add-node reset-arm-node)
      (send sm-sub :add-node reset-carrot-node)
      
      (send sm-sub :goal-state :success)
      (send sm-sub :start-state grasp-carrot-node)
      (send sm-sub :add-transition grasp-carrot-node set-carrot-peel-node :success)
      (send sm-sub :add-transition set-carrot-peel-node peel-node :success)
      (send sm-sub :add-transition peel-node reset-rarm-node :success)
      (send sm-sub :add-transition reset-rarm-node put-carrot-node :success)
      (send sm-sub :add-transition put-carrot-node :success :success)
      
      (send sm-sub :add-transition grasp-carrot-node reset-arm-node :fail)
      (send sm-sub :add-transition set-carrot-peel-node reset-arm-node :fail)
      (send sm-sub :add-transition reset-arm-node reset-carrot-node :success)
      (send sm-sub :add-transition reset-carrot-node :success :success)

      (send sm-sub :add-transition peel-node set-carrot-peel-node :fail)
      )
    
    sm-top))

    ;; (setq count 0) ;; 失敗した数を数える．
    ;; (setq sm
    ;;       (make-state-machine
    ;;        ;; define graph,  list of (<from-node> <transition> <to-node>)
    ;;        ;; if <transition> is ->, it corresponds when node returns t and !-> for nil.
    ;;        '((:init :success :peel-half)
    ;;          (:peel-half :success :rotate-carrot)
    ;;          (:rotate-carrot :success :peel-rest)
    ;;          (:peel-rest :success :done)
    ;;          )
    ;;        ;; define function map
    ;;        '((:init '(lambda (&rest args) (init) :success))
    ;;          (:peel-half '(lambda (&rest args) (curry-1-7-1) :success))
    ;;          (:rotate-carrot '(lambda (&rest args) (curry-1-7-2) :success))
    ;;          (:peel-rest '(lambda (&rest args) (curry-1-7-3) :success))
    ;;          )
    ;;        ;; initial state
    ;;        '(:init)
    ;;        ;; goal state
    ;;        '(:done)))))

(defun smach-demo-1-7 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-1-7)))

(format t ";; to run with smachk, run ~% (smach-demo-1-7) ~%")

