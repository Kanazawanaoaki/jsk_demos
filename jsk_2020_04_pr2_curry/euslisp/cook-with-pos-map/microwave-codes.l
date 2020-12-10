(defun microwave-codes-init ()
  ;; (require :pr2-microwave-interface "package://microwave_pr2_201710/euslisp/lib/pr2-microwave-interface.l")
  (require :pr2-microwave-interface "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/lib-microwave/my-pr2-microwave-interface.l")
  
  (unless (boundp '*pmi*) (setq *pmi* (instance pr2-microwave-interface :init)))
  (send *pmi* :kanazawa-pose)
  
  (warn "please run (recieve-sato) or (recognition) ~%")
  )

(microwave-codes-init)

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

(defun tmp-test ()
  (recieve-sato)
  (recognition)
  (micro-all)
  )
