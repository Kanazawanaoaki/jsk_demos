;; add for sense
(ros::roseus "stove_rec_test" :anonymous t)
(setq *topic-name* "/speech_to_text")
(ros::load-ros-manifest "speech_recognition_msgs")

(defun test-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (format t "data: ~A ~%" *data*)
    ) 
  )

(ros::unsubscribe "/speech_to_text")
(setq *topic-name* "/speech_to_text")
(setq *cb-flag* nil)
(ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'test-cb)


(defun test ()
  (do-until-key
   (ros::spin-once)
   (ros::sleep)
   )
  )

(test)

