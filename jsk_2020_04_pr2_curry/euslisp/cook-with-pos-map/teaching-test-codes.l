(defun teaching-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

  ;; 揺するやつ
  (load "package://jsk_demo_common/euslisp/pr2-action.l")
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(teaching-init)

(warn "~% there are teaching funcs  ~%")


;; add for remember
(defun list-init ()
  (setq *avs* (list))
  (setq *r-cds* (list))  
  (setq *l-cds* (list))  
  )



(defun remember-test ()
  (do-until-key
   (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
   (setq av (send *pr2* :angle-vector))
   (setq *avs* (append *avs* (list av)))
   (setq *r-cds* (append *r-cds* (list (send *pr2* :rarm :end-coords))))
   (setq *l-cds* (append *l-cds* (list (send *pr2* :larm :end-coords))))
   (print av)
   (unix:usleep 100)
   )
  )
