(defun garbage-codes-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  
  ;; trashbox (garbage-can)
  (load "models/room73b2-trashbox0-object.l")
  (setq *trashbox0* (room73b2-trashbox0))
  (send *trashbox0* :newcoords (send *trashbox0-coords* :copy-worldcoords))
  
  
  (move-to-seasoning-irt)
  (objects (list *pr2* *scene* *trashbox0*))
  (update-view)
  )

(garbage-codes-init)


