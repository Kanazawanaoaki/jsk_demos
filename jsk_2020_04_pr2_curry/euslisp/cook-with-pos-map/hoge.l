(defun ih-init ()
  ;; init
  (load "tool-use-codes.l")

  ;; set pot
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cooking-pot-73b2.l")
  (setq *pot* (cooking-pot))
  (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))
  

  ;; def global coords
  (setq *pot-larm-from-above* (make-coords :pos (float-vector 639 8109 30971) :rpy (float-vector -3.069 1.306 -0.087)))
  (setq *pot-larm-from-below* (make-coords :pos (float-vector 644 8104 30947) :rpy (float-vector 3.125 -0.909 3.119)))

  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *spatula* *ladle* *pot*))
  (update-view)
  )

(ih-init)


(setq *arrow1* (arrow))
(send *arrow1* :newcoords (make-coords :pos (float-vector 427.739 8071.081 30846.132) :rpy (float-vector -2.267 0.887 0.091)))

(setq *arrow2* (arrow))
(send *arrow2* :newcoords (make-coords :pos (float-vector 509.423 8110.011 30860.304) :rpy (float-vector -2.038 1.081 0.261)))

(setq *arrow3* (arrow))
(send *arrow3* :newcoords (make-coords :pos (float-vector 468 8090 30850) :rpy (float-vector -2.038 1.081 0.261)))


;; (objects (list *pr2* *scene* *spatula* *ladle* *pot* *arrow1* *arrow2* *arrow3*))
;; (update-view)

(setq *cds1* (make-cascoords :pos (float-vector 427.739 8071.081 30850)))
(send *arrow3* :assoc *cds1*)

(objects (list *pr2* *scene* *spatula* *ladle* *pot* *arrow1* *arrow3*))
(update-view)

;; 回転させるプログラムを書く．
(defun rotate-test ()
  (send *arrow3* :rotate (deg2rad 30) :z :world)
  (send *arrow1* :newcoords (make-coords :pos (send (send *cds1* :copy-worldcoords) :worldpos) :rpy (float-vector -2.267 0.887 0.091)))
  (update-view)
  )
