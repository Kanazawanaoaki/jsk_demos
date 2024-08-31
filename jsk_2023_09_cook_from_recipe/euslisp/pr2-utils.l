#!/usr/bin/env roseus

(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :kanazawa-roseus-utils "package://jsk_2023_09_cook_from_recipe/euslisp/kanazawa-roseus-utils.l")

(defun init-pr2 ()
  (unless (boundp '*ri*) (pr2-init))
  (unless (boundp '*robot*) (setq *robot* *pr2*))
  (objects *robot*)
  (unless (member *pr2* *view-objects*)
    (setq *view-objects* (append *view-objects* (list *pr2*))))
  ;; (send *robot* :reset-manip-pose) ;; TODO change
  )

;; dialog
(ros::load-ros-manifest "speech_recognition_msgs")
(setq *voice-data-flag* nil)

(defun voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *voice-data* (send *msg* :transcript))
    (setq *voice-data-flag* t)
    (format t "voice-data: ~A ~%" *voice-data*)
    )
  )

(defun dialogue-func ()
  (ros::unsubscribe "/speech_to_text")
  (setq *voice-data-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-cb)
  (format t "wait for speak ~%")
  (until *voice-data-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  ;; (send *ri* :speak-jp "ありがとうございます")
  ;; (unix:sleep 1)
  )

(defun speak-with-log (speak-word &key (lang "jp") (wait t))
  (if (send *ri* :simulation-modep) ;; kinematic simulatorでは喋れない
      (unix:usleep 500000)
    (send *ri* :speak-jp speak-word :wait wait)
    )
  (format t "[PR2 speak] ~A ~%" speak-word)
  )

(defun ik-fail-report (&key (wait t)) ;; TODO ask support?
  (speak-with-log "I Kを解くのに失敗しました")
  (when wait
    (do-until-key
     (print "wait for key pressed (after IK fail)")
     (unix:usleep 100000)
     )
    ))

;; manequine mode
(ros::load-ros-manifest "pr2_mechanism_msgs")
;; (ros::wait-for-service "/pr2_controller_manager/switch_controller")

(defun manequine-mode (&key (arm (list "rarm")) (start t))
  (let ((req (instance pr2_mechanism_msgs::SwitchControllerRequest :init))
	(normal-controllers (list))
	(loose-controllers (list))
	)
    (dolist (e arm)
      (if (equal e "rarm")
          (progn
            (setq normal-controllers (append normal-controllers (list "r_arm_controller")))
            (setq loose-controllers (append loose-controllers (list "r_arm_controller_loose")))
            )
        )
      (if (equal e "larm")
          (progn
            (setq normal-controllers (append normal-controllers (list "l_arm_controller")))
            (setq loose-controllers (append loose-controllers (list "l_arm_controller_loose")))
            )
        )
      (if (equal e "head")
          (progn
            (setq normal-controllers (append normal-controllers (list "head_traj_controller")))
            (setq loose-controllers (append loose-controllers (list "head_traj_controller_loose")))
            )
        ))
    (if start
        (progn
          (send req :start_controllers loose-controllers)
          (send req :stop_controllers normal-controllers)
          (format t "start ~A manequine mode! ~%" arm)
          )
      (progn
        (send req :start_controllers normal-controllers)
        (send req :stop_controllers loose-controllers)
        (format t "stop ~A manequine mode! ~%" arm)
        )
      )
    (setq res (ros::service-call "/pr2_controller_manager/switch_controller" req))
    (format t "controller service response: ~A ~%" (send res :ok))
    ))

(defun manequine-end ()
  (manequine-mode :arm (list "rarm" "larm" "head") :start nil) ;;マネキンoff
  )

(defun manequine-both ()
  (manequine-mode :arm (list "rarm" "larm") :start t) ;;マネキンon only arm
  )

(defun manequine-all ()
  (manequine-mode :arm (list "rarm" "larm" "head") :start t) ;;マネキンon all (arm & head)
  )

(defun servo-off-mode (&key (arm (list "rarm")) (start t))
  (let ((req (instance pr2_mechanism_msgs::SwitchControllerRequest :init))
        (normal-controllers (list))
        (loose-controllers (list))
        )
    (dolist (e arm)
      (if (equal e "rarm")
          (progn
            (setq normal-controllers (append normal-controllers (list "r_arm_controller" "r_arm_controller_loose")))
            (setq loose-controllers (append loose-controllers (list "")))
            )
        )
      (if (equal e "larm")
          (progn
            (setq normal-controllers (append normal-controllers (list "l_arm_controller" "l_arm_controller_loose")))
            (setq loose-controllers (append loose-controllers (list "")))
            )
        ))
    (if start
        (progn
          (send req :start_controllers loose-controllers)
          (send req :stop_controllers normal-controllers)
          (format t "start ~A manequine mode! ~%" arm)
          )
      (progn
        (send req :start_controllers normal-controllers) ;; manequineになるっぽい
        (send req :stop_controllers loose-controllers)
        (format t "stop ~A manequine mode! ~%" arm)
        )
      )
    (setq res (ros::service-call "/pr2_controller_manager/switch_controller" req))
    (format t "controller service response: ~A ~%" (send res :ok))
    ))



;; init
(init-pr2)
;;
