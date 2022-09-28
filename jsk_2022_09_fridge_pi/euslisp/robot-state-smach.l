#!/usr/bin/env roseus

(load "package://roseus_smach/src/state-machine-ros.l")
(load "package://roseus_smach/src/state-machine-utils.l")
(load "package://roseus_smach/src/state-machine.l")

(ros::roseus "robot_state_smach")

(setq *is-movable* nil)
(setq *task-doing* nil)

(defun movable-cb (msg)
  (setq *is-movable* (send msg :data))
  )
(defun task-cb (msg)
  (setq *task-doing* (send msg :data))
  )

(ros::subscribe "robot_state/is_movable" std_msgs::Bool #'movable-cb)
(ros::subscribe "robot_state/task_doing" std_msgs::Bool #'task-cb)
(ros::advertise "robot_state/state" std_msgs::string 1)

(defun func-unmovable (&rest args)
  (format t "Execute state unmovable~%")
  (setq *is-movable* nil)
  (ros::rate 10)
  (until *is-movable*
         (setq msg (instance std_msgs::string :init))
         (send msg :data "unmovable")
         (ros::publish "robot_state/state" msg)
         (ros::spin-once)
         )
  :make-movable)

(defun func-standby (&rest args)
  (format t "Execute state standby~%")
  (setq *task-doing* nil)
  (setq *is-movable* t)
  (ros::rate 10)
  (while (and (not *task-doing*) *is-movable*)
    (setq msg (instance std_msgs::string :init))
    (send msg :data "standby")
    (ros::publish "robot_state/state" msg)
    (ros::spin-once)
    )
  (if *task-doing*
      :start-task
      :become-unmovable))

(defun func-task (&rest args)
  (format t "Execute state task-in-operation~%")
  (setq *task-doing* t)
  (ros::rate 10)
  (while *task-doing*
    (setq msg (instance std_msgs::string :init))
    (send msg :data "task-in-operation")
    (ros::publish "robot_state/state" msg)
    (ros::spin-once)
    )
  :finish-task)

(defun robot-state-smach ()
  (let ((sm (instance state-machine :init)))
    (send sm :add-node (instance state :init :unmovable 'func-unmovable))
    (send sm :add-node (instance state :init :standby 'func-standby))
    (send sm :add-node (instance state :init :task-in-operation 'func-task))
    ;; ;; goal-states are generated in this method
    ;; (send sm :goal-state (list :outcome4 :outcome5))

    ;; select a node as start-node
    (send sm :start-state :unmovable)
    ;; from and to nodes are selected by name or symbol
    (send sm :add-transition :unmovable :standby :make-movable)
    (send sm :add-transition :standby :unmovable :become-unmovable)
    (send sm :add-transition :standby :task-in-operation :start-task)
    (send sm :add-transition :task-in-operation :standby :finish-task)
    sm ))

(defun exec-robot-state-smach () (exec-state-machine (robot-state-smach)))

(warn ";;(exec-robot-state-smach)~%")
(exec-robot-state-smach)
