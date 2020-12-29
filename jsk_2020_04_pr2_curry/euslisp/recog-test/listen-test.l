;; add for sense

(ros::roseus "speech_rec_test" :anonymous t)
(ros::load-ros-manifest "speech_recognition_msgs")

(defun test-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (if (equal *data* '("OK"))
        (progn 
          (format t "了解しました！ ~%" *data*)
          )
      (format t "data: ~A ~%" *data*)
      ) 
    )
  )

(ros::unsubscribe "/speech_to_text")
(setq *cb-flag* nil)
(ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'test-cb)

(defun test ()
  (do-until-key
   (ros::spin-once)
   (ros::sleep)
   )
  )

(test)

