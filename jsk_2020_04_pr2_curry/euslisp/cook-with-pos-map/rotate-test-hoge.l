(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")


;; test spatula codes

(set-pose)
(set-spatula)
(mix-with-spatula-set)
;; (setq *debug-flag* t)

(rotate-mix-with-spatula)


(defun ik-test ()
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target (car (send *spatula* :attention))
    :rotation-axis t
    :debug-view t)
  )

(load "models/arrow-object.l")
(setq *arrow* (arrow))

(objects *arrow*)
(update-view)
;; (send *arrow* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector -2.316 0.365 0.061)))

(send *arrow* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector -2.288 0.713 0.075)))

(warn "please run (ik-test) ~%")



;; ;; test ladle codes
;; (set-pose)
;; (set-ladle)
;; (mix-with-ladle-set)

;; ;; (rotate-mix-with-ladle)


;; (defun ik-test ()
;;   (send *pr2* :rarm :inverse-kinematics
;;     (send *arrow* :copy-worldcoords)
;;     :move-target (elt (send *ladle* :attention) 1)
;;     :rotation-axis t
;;     :debug-view t)
;;   )

;; (load "models/arrow-object.l")
;; (setq *arrow* (arrow))

;; (objects *arrow*)
;; (update-view)

;; (send *arrow* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector 0.251 1.492 -0.625)))
;; (warn "please run (ik-test) ~%")
