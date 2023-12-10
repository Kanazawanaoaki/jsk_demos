(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :arrow-object "models/arrow-object.l")

(pr2)
(setq *arrow* (arrow))
(setq *arrow1* (arrow))
(setq *arrow2* (arrow))

(objects (list *pr2* *arrow* *arrow1* *arrow2*))

(defun change-coords (now-cds)
  (setq ans (make-coords))
  (send ans :transform (send now-cds :copy-worldcoords))
  (send ans :rotate (deg2rad -90) :y)
  (send ans :rotate (deg2rad 180) :z)
  ans)

(defun calc-diff (now-idealcds now-cds)
  (let (cds
        diffcds)
    ;; (setq cds
    ;;       (make-coords :pos
    ;;                    (float-vector (elt (send now-cds :worldpos) 0)
    ;;                                  (elt (send now-cds :worldpos) 1)
    ;;                                  0)
    ;;                    :rot (send now-cds :copy-rot)))
    (setq diffcds (make-coords))
    ;; (setq diffcds (send (send now-idealcds :inverse-transformation)
    ;;                     :transform (send cds :worldcoords) :world))
    (setq diffcds (send (send now-idealcds :inverse-transformation)
                        :transform (send now-cds :worldcoords) :world))
    diffcds))

(defun calc-diff-old (now-idealcds now-cds)
  (let (cds
        idealcds
        diffcds)
    (setq idealcds
          (make-coords :pos
                       (float-vector (elt (send now-idealcds :worldpos) 0)
                                     (elt (send now-idealcds :worldpos) 1)
                                     0)
                       :rpy (list (elt (car (rpy-angle (send now-idealcds :worldrot))) 0)
                                  0 0)))
    (setq cds
          (make-coords :pos
                       (float-vector (elt (send now-cds :worldpos) 0)
                                     (elt (send now-cds :worldpos) 1)
                                     0)
                       :rpy (list (elt (car (rpy-angle (send now-cds :worldrot))) 0)
                                  0 0)))
    (setq diffcds (make-coords))
    (setq diffcds (send (send idealcds :inverse-transformation)
                        :transform (send cds :worldcoords) :world))
    diffcds))


(setq idealcds (make-coords :pos (float-vector 1148 313 1419.172)
                            :rpy (float-vector 0.754 1.547 -2.402)))
;; (setq idealcds (make-coords :pos (float-vector 1148 313 0)
;;                             :rpy (float-vector 0.754 1.547 -2.402)))
;; (setq idealcds (make-coords :pos (float-vector 1148 313 0)
;;                             :rpy (float-vector 0.754 0 0)))

;; (setq cds (make-coords :pos (float-vector 1134.241 321.186 1418.702)
;;                        :rpy (float-vector 0.381 1.521 -2.795)))
;; (setq cds (make-coords :pos (float-vector 1134.241 321.186 0)
;;                        :rpy (float-vector 0.381 0 0)))

;; (setq cds (make-coords :pos (float-vector 1185.391 59.003 1416.98)
;;                        :rpy (float-vector 0.021 1.528 -2.868)))

(setq cds (make-coords :pos (float-vector 1009.382 586.861 1423.349)
                       :rpy (float-vector 0.411 1.458 -3.035)))
;; (setq cds (make-coords :pos (float-vector 1009.382 586.861 0)
;;                        :rpy (float-vector 0.411 1.458 -3.035)))

(setq idealcds-tmp (change-coords idealcds))
(setq cds-tmp (change-coords cds))



(send *arrow* :reset-coords)
(send *arrow* :transform (send cds :copy-worldcoords)) ;; 今の座標から見たターゲット座標

(setq diffcds (calc-diff idealcds cds))

(send *arrow1* :reset-coords)
(send *arrow1* :transform (send diffcds :copy-worldcoords)) ;; 移動目標

(setq estimated (send (send diffcds :copy-worldcoords) :transform (send idealcds :copy-worldcoords)))

(send *arrow2* :reset-coords)
(send *arrow2* :transform (send estimated :copy-worldcoords)) ;; 移動目標からみたターゲット座標

(print idealcds)
(print cds)
(print diffcds)
(print estimated)
