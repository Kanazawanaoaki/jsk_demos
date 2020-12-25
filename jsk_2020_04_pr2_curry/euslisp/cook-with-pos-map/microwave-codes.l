(defun microwave-codes-init ()
  ;; (require :pr2-microwave-interface "package://microwave_pr2_201710/euslisp/lib/pr2-microwave-interface.l")
  (require :pr2-microwave-interface "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/lib-microwave/my-pr2-microwave-interface.l")
  
  (unless (boundp '*pmi*) (setq *pmi* (instance pr2-microwave-interface :init)))
  (send *pmi* :kanazawa-pose)
  
  (setq *wait-num* 3)
  
  (warn "please run (recieve-sato) or (recognition) ~%")
  )

(microwave-codes-init)


;; add for rec
(ros::roseus "microwave_rec_test" :anonymous t)
(ros::load-ros-package "roseus")

(defun microwave-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    )
  )

;; add for rosservice
(ros::load-ros-manifest "std_srvs")
;; (ros::wait-for-service "after_stow_data_collection/save_request")
(setq req (instance std_srvs::TriggerRequest :init))

(defun rossrv-test ()
  (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
  )



(defun recieve-sato ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *ri* :speak-jp "サトウのごはんを握らせて下さい")
  (unix::sleep 3)
  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please run (recognition) ~%")
  )

(defun recognition ()
  (send *pmi* :update-microwave-pose)
  (warn "please run (micro-all) or (hot-veg-micro) ~%")
  )

(defun micro-all ()
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 2 60))

  ;; take object from microwave
  (send *pmi* :open-microwave)
  ;; (send *pmi* :kanazawa-take-object)
  ;; (send *pmi* :close-microwave)
  
  )

(defun hot-veg-micro ()
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 3 60))
  
  ;; take object from microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-take-object)
  (send *pmi* :close-microwave)
  )

(defun button-test ()
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  )


(defun button-test-with-rec ()
  ;; push button
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-500w-button)
    (unix:sleep *wait-num*)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (equal *data* "/500w")
        (setq *push-flag* t))
    )
  
  ;; ここは二回押していたらどうするとかがあっても良い．
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-1min-button)
    (unix:sleep *wait-num*)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (equal *data* "/1m")
        (setq *push-flag* t))
    )
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-1min-button)
    (unix:sleep *wait-num*)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (equal *data* "/2m")
        (setq *push-flag* t))
    )

  (setq *tmp-data* *data*)
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-start-button)
    (unix:sleep *wait-num*)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (or (equal *data* "/start") (not (equal *data* *tmp-data*)))
        (setq *push-flag* t))
    )
  )

(defun tmp-test ()
  (recieve-sato)
  (recognition)
  (micro-all)
  )
