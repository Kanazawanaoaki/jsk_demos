(load "package://pr2eus/pr2-interface.l")
;; (load "package://informatized_body_core/euslisp/informatized-body-core.l")
;; (load "package://informatized_body_utils/euslisp/informatized-body-utils.l")
;; (load "package://informatized_body_core/euslisp/informatized-body-core.l")
;; (initialize-ibm-core "pr2_imitation")
;; (initialize-ibm-utils "pr2_imitation")

(defun init-pr2 ()
  (pr2-init)
  (setq *robot* *pr2*)
  (objects *robot*)
  (send *robot* :reset-manip-pose) ;; TODO change
  ;; (ros::advertise "/pr2_imitation/controller/target_state" informatized_body_msgs::TargetState 1)
  )

(defun reset-manip-pose ()
  (send *robot* :reset-manip-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  )

(defun get-image-latent (&key (filename "/tmp/target.png"))
  (get-image-latent-base "pr2_imitation" :filename filename))

(defun save-image (&key (filename "/tmp/target.png"))
  (save-image-base "pr2_imitation" :filename filename))

(defun sample-codes ()
  (send *ri* :stop-grasp)
  (send *ri* :start-grasp)
  (send *ri* :state :potentio-vector)
  (send *robot* :reset-manip-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector))
  )

;; add for kanazawa yaml handling
(defun load-yaml-config (config-file)
  (let ((control_joints nil))
    (unix:system (format nil "rosparam load ~A yaml_load_eus" config-file))
    (setq control_joints (ros::get-param "/yaml_load_eus/control_joints"))
    (setq dim_list (ros::get-param "/yaml_load_eus/dim_list"))
    (setq initial_joints (ros::get-param "/yaml_load_eus/initial_joints"))
    (format t "~%load params from ~A ~%" config-file)
    (format t " now control_joints is ~A ~%" control_joints)
    (format t " now dim_list is ~A ~%" dim_list)
    (format t " now initial_joints is ~A ~%" initial_joints)
    (list control_joints dim_list initial_joints)))

(defun load-config-from-name (config-name)
  (let ((file-path nil))
    (setq file-path (ros::resolve-ros-path (format nil "package://informatized_pr2_imitation/config/~A" config-name)))
    (format t "now path is ~A ~%" file-path)
    (load-yaml-config file-path)
    ))

;; ;; add for kanazawa data record

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
  (until *voice-data-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  ;; (send *ri* :speak-jp "ありがとうございます")
  ;; (unix:sleep 1)
  )

;; manequine
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

;; data_collection
(ros::load-ros-manifest "std_srvs")

(defun trigger-request (service)
  (setq req (instance std_srvs::TriggerRequest :init))
  (setq res (ros::service-call service req t))
  )

(defun start-data-collection (&key (service "data_collection_rosbag_test/start_request"))
  (trigger-request service)
  )

(defun end-data-collection (&key (service "data_collection_rosbag_test/end_request"))
  (trigger-request service)
  )

;; data collection duka
(defun data-collection-start (&key (filename nil))
  (data-collection-start-base "pr2_imitation" :filename filename))

(defun data-collection-stop ()
  (data-collection-stop-base "pr2_imitation"))
