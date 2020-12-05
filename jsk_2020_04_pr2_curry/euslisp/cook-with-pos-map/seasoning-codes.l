(defun water-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  
  ;; set objects
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/solt.l")
  (setq *solt* (solt))
  (send *solt* :newcoords (send *solt-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/dispenser.l")
  (setq *dispenser* (dispenser))
  (send *dispenser* :newcoords (send *dispenser-coords* :copy-worldcoords))

  (move-to-seasoning-irt)
  (objects (list *pr2* *scene* *solt* *dispenser*))
  (update-view)
  )

(water-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (grasp-lever) ~%")


;; def util-funcs
(defun reset-rarm ()
  (setq *rav0* (float-vector -25.6468 7.87241 -48.2704 -85.3763 253.675 -77.8887 -147.102))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  (setq *rav1* (float-vector -20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *pr2* :rarm :angle-vector *rav3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

