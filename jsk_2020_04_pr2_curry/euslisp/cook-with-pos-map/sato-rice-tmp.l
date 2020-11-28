(defun sato-init ()
  (require :pr2-microwave-interface "package://microwave_pr2_201710/euslisp/lib/pr2-microwave-interface.l")

  (setq *pmi* (instance pr2-microwave-interface :init))
  (send *pmi* :kanazawa-pose)
  
  (warn "please run (recieve-sato) or (tmp-test) ~%")
  )

(sato-init)

(defun recieve-sato ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *ri* :speak-jp "サトウのご飯を握らせて下さい")
  (unix::sleep 3)
  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please run (recognition) ~%")
  )

(defun recognition ()
  (send *pmi* :update-microwave-pose)
  (warn "please run (micro-all) ~%")
  )

(defun micro-all ()
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)

  ;; push button
  (send *ri* :start-grasp :rarm :wait t)
  (send *pmi* :push-button (float-vector -70 -380 85))
  (send *pmi* :push-button (float-vector -70 -400 100))
  (send *pmi* :push-button (float-vector -70 -400 100))
  (send *pmi* :push-button (float-vector -60 -410 175))
  (send *pr2* :reset-pose)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)           
  (send *ri* :wait-interpolation)    
  
  ;; (send *pmi* :push-500w-button)
  ;; (send *pmi* :push-1min-button)
  ;; (send *pmi* :push-1min-button)
  ;; (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 2 60))

  ;; take object from microwave
  (send *pmi* :open-microwave)
  ;; (send *pmi* :kanazawa-take-object)
  ;; (send *pmi* :close-microwave)
  
  )

(defun tmp-test ()
  (recieve-sato)
  (recognition)
  (micro-all)
  )
