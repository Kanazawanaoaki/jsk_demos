(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")


;; ;; test spatula codes

;; (set-spatula)
;; (mix-with-spatula-set)
;; ;; (setq *debug-flag* t)

;; ;; (rotate-mix-with-spatula)

;; (load "models/arrow-object.l")
;; (setq *arrow* (arrow))

;; (objects *arrow*)
;; (update-view)


;; (defun ik-test ()
;;   (send *pr2* :rarm :inverse-kinematics
;; 	(send *arrow* :copy-worldcoords)
;; 	:move-target (car (send *spatula* :attention))
;; 	:rotation-axis t
;; 	:debug-view t)
;;   )



;; ;; (send *arrow* :newcoords (make-coords :pos (float-vector 485.355 8085.355 30845.0) :rpy (float-vector -2.267 0.887 0.091))) ;;回転し始める座標
;; ;; (send *arrow* :newcoords (make-coords :pos (float-vector 427.739 8071.081 30850) :rpy (float-vector -2.267 0.887 0.091)))
;; ;; (send *arrow* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector -2.267 0.887 0.091)))

;; (send *arrow* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector -2.316 0.365 0.061)))


;; test ladle codes

