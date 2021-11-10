#!/usr/bin/env roseus
(defun kinematics-ih-init ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/ih-use-stove-with-primitives-codes.l")
  )

(defun additional-init ()
  ;; IHコンロ利用の前の準備
  (set-pose)
  (ready-pose)
  )

(kinematics-ih-init)
(warn "please run (additional-init) ~%")

;; action codes とりあえず認識やカメラの視線の事は考えずにプログラムを書く
(defun push-knob-on-action (&rest args)
  (push-knob)
  (format t "push knob on! ~%")
  )

(defun rotate-knob-action (&rest args)
  (grasp-knob)
  (rotate-knob)
  (format t "rotate knob! ~%")
  )

(defun rotate-knob-right-action (&rest args)
  (rotate-knob :deg 30)
  (format t "rotate knob right! ~%")
  )

(defun rotate-knob-left-action (&rest args)
  (rotate-knob :deg -30)
  (format t "rotate knob left! ~%")
  )

(defun push-knob-off-action (&rest args)
  (release-knob)
  (push-knob)
  (format t "push knob off! ~%")
  )
