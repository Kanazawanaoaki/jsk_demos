(defun microwave-codes-init ()
  ;; (require :pr2-microwave-interface "package://microwave_pr2_201710/euslisp/lib/pr2-microwave-interface.l")
  (require :pr2-microwave-interface "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/lib-microwave/my-pr2-microwave-interface.l")
  
  (unless (boundp '*pmi*) (setq *pmi* (instance pr2-microwave-interface :init)))
  (send *pmi* :kanazawa-pose)
  
  ;; set global num
  (setq *wait-num* 3)
  (setq *w-time* 2)
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

(defun panel-reader-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    (if (ros::time> (send *msg* :header :stamp) *now*)
        (setq *cb-flag* t)
      )
    ))

(defun read-panel ()
  (setq *now* (ros::time-now))
  (ros::unsubscribe "/microwave_reader/result")
  (setq *cb-flag* nil)
  (ros::subscribe "/microwave_reader/result" roseus::StringStamped #'panel-reader-cb)
  (until *cb-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  )

;; add for rosservice
(ros::load-ros-manifest "std_srvs")
;; (ros::wait-for-service "after_stow_data_collection/save_request")
(setq req (instance std_srvs::TriggerRequest :init))

(defun rossrv-test ()
  (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
  )

;; add for voice recognition
(ros::load-ros-manifest "speech_recognition_msgs")
(setq *data-flag* nil)
(defun voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (setq *data-flag* t)
    (format t "data: ~A ~%" *data*)
    )
  )

(defun dialogue-func ()
  (ros::unsubscribe "/speech_to_text")
  (setq *data-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-cb)
  (until *data-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (send *ri* :speak-jp "ありがとうございます")
  (unix:sleep 1)
  )

(setq *ok-flag* nil)
(defun voice-ok-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (if (equal *data* '("OK"))
        (progn
          (format t "了解しました！ ~%" *data*)
          (setq *ok-flag* t)
          )
      (format t "data: ~A ~%" *data*)
      ) 
    )
  )

(defun ok-wait ()
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
         (ros::spin-once)
         (ros::sleep)
         )  
  (send *ri* :speak-jp "ありがとうございます")
  (unix:sleep *w-time*)
  )


(defun ok-grasp ()
  (ok-wait)
  (send *ri* :start-grasp :rarm :wait t)
  )

(defun receive-with-dialogue ()
  ;; (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい") ;; 喋らせている想定でスタート
  (setq *yes-flag* nil)
  (until *yes-flag*
         (send *ri* :stop-grasp :rarm :wait t)
         (ok-grasp)
         (send *ri* :speak-jp "上手く掴めていますか？")
         (dialogue-func)
         (if (equal *data* '("はい"))
             (setq *yes-flag* t)
           (progn
             (send *ri* :speak-jp "グリッパを開きます.もう一度お願いします")
             (unix:sleep *w-time*)
             )
           )
         )
  
  (send *ri* :speak-jp "次の行動に移ります")
  (unix:sleep *w-time*)
  )


(warn "please run (recieve-sato) or (recognition) ~%")

;; def funcs
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
  
  ;; ここは二回押していたらどうするとかがあっても良いようにしたい．
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

(defun button-test-with-rec-stamp ()
  ;; push button
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-500w-button)
    (read-panel)
    (if (equal *data* "/500w")
        (setq *push-flag* t))
    )
  
  ;; ここは二回押していたらどうするとかがあっても良いようにしたい．
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-1min-button)
    (read-panel)
    (if (equal *data* "/1m")
        (setq *push-flag* t))
    )
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-1min-button)
    (read-panel)
    (if (equal *data* "/2m")
        (setq *push-flag* t))
    )

  (setq *tmp-data* *data*)
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-start-button)
    (read-panel)
    (if (or (equal *data* "/start") (not (equal *data* *tmp-data*)))
        (setq *push-flag* t))
    )
  )


(defun sato-push-button-with-rec ()
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
  
  ;; ここは二回押していたらどうするとかがあっても良いようにしたい． ;; TODO
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

(defun sato-push-button-with-rec-stamp ()
  ;; push button
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-500w-button)
    (read-panel)
    (if (equal *data* "/500w")
        (setq *push-flag* t))
    )
  
  ;; ここは二回押していたらどうするとかがあっても良いようにしたい． ;; TODO
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-1min-button)
    (read-panel)
    (if (equal *data* "/1m")
        (setq *push-flag* t))
    )
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-1min-button)
    (read-panel)
    (if (equal *data* "/2m")
        (setq *push-flag* t))
    )

  (setq *tmp-data* *data*)
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (send *pmi* :push-start-button)
    (read-panel)
    (if (or (equal *data* "/start") (not (equal *data* *tmp-data*)))
        (setq *push-flag* t))
    )
  )

(defun sato-rice-micro-with-rec ()
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (sato-push-button-with-rec)
  
  ;; wait for heating
  (unix::sleep (* 2 60))
  
  ;; take object from microwave
  (send *pmi* :open-microwave)
  ;; (send *pmi* :kanazawa-take-object)
  ;; (send *pmi* :close-microwave)

  (send *ri* :speak-jp "サトウのごはんを温めました")
  (unix:sleep 2)
  )

(defun sato-rice-micro-with-rec-stamp ()
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (sato-push-button-with-rec-stamp)
  
  ;; wait for heating
  (unix::sleep (* 2 60))
  
  ;; take object from microwave
  (send *pmi* :open-microwave)
  ;; (send *pmi* :kanazawa-take-object)
  ;; (send *pmi* :close-microwave)

  (send *ri* :speak-jp "サトウのごはんを温めました")
  (unix:sleep 2)
  )

;; TODO
(defun sato-push-button-with-rec-with-dialogue ()
  ;; push 500w button
  (setq *push-flag* nil)
  (setq cnt 0)
  (while (eql *push-flag* nil)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (equal *data* "/500w")
        (setq *push-flag* t)
      (progn
        (if (> cnt 2) ;;もし二回以上トライしていたら助けを求める
            (progn
              (send *ri* :speak-jp "レンジのボタンを押して500wにセットして，合図をしてください")
              (ok-wait)
              )
          (progn
            (send *pmi* :push-500w-button)
            (unix:sleep *wait-num*)
            (setq cnt (+ cnt 1))
            )
          )
        )
      )
    )

  ;; push 1min button x2
  (setq *push-flag* nil)
  (setq tmp "/500w")
  (setq cnt 0)
  (while (eql *push-flag* nil)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (equal *data* "/2m")
        (setq *push-flag* t)
      (progn
        (if (> cnt 2) ;;もし二回以上トライしていたら助けを求める
            (progn
              (send *ri* :speak-jp "1分のボタンを押して2分にセットして，合図をしてください")
              (ok-wait)
              )
          (progn
            (send *pmi* :push-1min-button)
            (unix:sleep *wait-num*)
            (if (equal *data* "/1m")
                (progn
                  (if (equal tmp *data*)
                      (setq cnt (+ cnt 1))
                    ))
              (setq cnt (+ cnt 1))
              )
            )
          )
        )
      )
    (setq tmp *data*)
    )
  
  (setq *tmp-data* *data*)
  (setq *push-flag* nil)
  (setq cnt 0)
  (while (eql *push-flag* nil)
    (setq msg (one-shot-subscribe "/microwave_reader/result" roseus::StringStamped :timeout 5000))
    (microwave-cb msg)
    (if (or (equal *data* "/start") (not (equal *data* *tmp-data*)))
        (setq *push-flag* t)
      (progn
        (if (> cnt 2) ;;もし二回以上トライしていたら助けを求める
            (progn
              (send *ri* :speak-jp "スタートのボタンを押して，合図をしてください")
              (ok-wait)
              )
          (progn
            (send *pmi* :push-start-button)
            (unix:sleep *wait-num*)
            (setq cnt (+ cnt 1))
            )
          )
        )
      )
    )
  )

(defun sato-rice-micro-with-rec-with-dialogue ()
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (sato-push-button-with-rec-with-dialogue)
  
  ;; wait for heating
  (unix::sleep (* 2 60))
  
  ;; take object from microwave
  (send *pmi* :open-microwave)
  ;; (send *pmi* :kanazawa-take-object)
  ;; (send *pmi* :close-microwave)

  (send *ri* :speak-jp "サトウのごはんを温めました")
  (unix:sleep 2)
  )

(defun recieve-sato-with-dialogue ()
  (send *pmi* :kanazawa-pose)
  

  (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい")
  (receive-with-dialogue)  
  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please run (recognition) ~%")
  )



;; def now funcs
(defun now-sato-rice-micro ()
  (recieve-sato)
  (recognition)
  (micro-all)
  ;; (sato-rice-micro-with-rec)
  )

(defun now-sato-rice-micro-with-dialogue ()
  (recieve-sato-with-dialogue)
  (recognition)
  ;; (micro-all)
  (sato-rice-micro-with-rec-with-dialogue)
  (recieve-sato-with-dialogue)
  )

(defun tmp-test ()
  (recieve-sato)
  (recognition)
  (micro-all)
  )
