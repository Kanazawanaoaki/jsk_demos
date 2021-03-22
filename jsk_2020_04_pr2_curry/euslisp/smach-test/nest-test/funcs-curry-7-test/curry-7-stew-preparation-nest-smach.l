#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine.l")
(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")

(load "curry-7-stew-preparation-nest-funcs.l")

(defun smach-curry-7 ()
  (let ((sm-sub-7 (instance state-machine :init))
        (sm-sub-7-4 (instance state-machine :init))
        )

    ;; sm-sub-7 ;;curry-7 stew-preparation
    (let ((init-node (instance state :init "INIT" '(lambda (&rest args) (curry-7-0) :success)))
          (move-to-kitchen-node (instance state :init "MOVE-TO-KITCHEN" '(lambda (&rest args) (curry-7-1) :success)))
          (transfer-to-pot-node (instance state :init "TRANSFER-TO-POT" '(lambda (&rest args) (curry-7-2) :success)))
          (grasp-mcup-node (instance state :init "GRASP-MCUP" '(lambda (&rest args) (curry-7-3) :success)))
          (fetch-water-node (instance state :init "FETCH-WATER" sm-sub-7-4))
          ;; (fetch-water-node (instance state :init "FETCH-WATER" '(lambda (&rest args) (curry-7-4) :success)))
          (put-mcup-node (instance state :init "PUT-MCUP" '(lambda (&rest args) (curry-7-5) :success)))
          (move-to-stove-node (instance state :init "MOVE-TO-STOVE" '(lambda (&rest args) (curry-7-6) :success)))
          (state-check-node (instance state :init "STATE-CHECK-NODE" '(lambda (&rest args) (curry-7-end) :success)))
          )
      (send sm-sub-7 :add-node init-node)
      (send sm-sub-7 :add-node move-to-kitchen-node)
      (send sm-sub-7 :add-node transfer-to-pot-node)
      (send sm-sub-7 :add-node grasp-mcup-node)
      (send sm-sub-7 :add-node fetch-water-node)
      (send sm-sub-7 :add-node put-mcup-node)
      (send sm-sub-7 :add-node move-to-stove-node)
      (send sm-sub-7 :add-node state-check-node)
      
      (send sm-sub-7 :goal-state :success)
      
      (send sm-sub-7 :start-state init-node)
      (send sm-sub-7 :add-transition init-node move-to-kitchen-node :success)
      (send sm-sub-7 :add-transition move-to-kitchen-node transfer-to-pot-node :success)
      (send sm-sub-7 :add-transition transfer-to-pot-node grasp-mcup-node :success)
      (send sm-sub-7 :add-transition grasp-mcup-node fetch-water-node :success)
      (send sm-sub-7 :add-transition fetch-water-node put-mcup-node :success)
      (send sm-sub-7 :add-transition put-mcup-node move-to-stove-node :success)
      (send sm-sub-7 :add-transition move-to-stove-node state-check-node :success)
      (send sm-sub-7 :add-transition state-check-node :success :success)

      ;; sm-sub-7-4 ;;curry-7-4-fetch-water
      (let ((move-to-sink-node (instance state :init "MOVE-TO-SINK" '(lambda (&rest args) (curry-7-4-1) :success)))
            (fetch-water-node (instance state :init "FETCH-WATER" '(lambda (&rest args) (curry-7-4-2) :success)))
            (move-to-kitchen-node (instance state :init "MOVE-TO-KITCHEN" '(lambda (&rest args) (curry-7-4-3) :success)))
            (pour-water-node (instance state :init "POUR-WATER" '(lambda (&rest args) (curry-7-4-4) :success)))
            (check-water-state-node (instance state :init "CHECK-WATER-STATE" '(lambda (&rest args) (curry-7-4-5) (check-water-state-func-tmp))))
            )
        (send sm-sub-7-4 :add-node move-to-sink-node)
        (send sm-sub-7-4 :add-node fetch-water-node)
        (send sm-sub-7-4 :add-node move-to-kitchen-node)
        (send sm-sub-7-4 :add-node pour-water-node)
        (send sm-sub-7-4 :add-node check-water-state-node)
        
        (send sm-sub-7-4 :goal-state :success)
        
        (send sm-sub-7-4 :start-state move-to-sink-node)
        (send sm-sub-7-4 :add-transition move-to-sink-node fetch-water-node :success)
        (send sm-sub-7-4 :add-transition fetch-water-node move-to-kitchen-node :success)
        (send sm-sub-7-4 :add-transition move-to-kitchen-node pour-water-node :success)
        (send sm-sub-7-4 :add-transition pour-water-node check-water-state-node :success)
        (send sm-sub-7-4 :add-transition check-water-state-node :success :success)
        (send sm-sub-7-4 :add-transition check-water-state-node move-to-sink-node :fail)
        )
      )
    sm-sub-7
    ))

(defun smach-demo-7 ()
  (ros::roseus "smach_demo")
  (exec-state-machine (smach-curry-7)))

(format t ";; to run with smachk, run ~% (smach-demo-7) ~%")

