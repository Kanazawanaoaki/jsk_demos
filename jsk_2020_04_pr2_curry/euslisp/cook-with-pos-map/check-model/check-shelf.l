(require :eng2-scene "package://jsk_2020_04_pr2_curry/euslisp/model/my-eng2-scene.l")

(load "package://jsk_2020_04_pr2_curry/euslisp/model/shelf-door.l")
(setq *shelf-door* (shelf-door))
(send *shelf-door* :newcoords (send *shelf-door-coords* :copy-worldcoords))

(load "models/arrow-object.l")
(setq *arrow* (arrow))
(setq *arrow1* (arrow))
(setq *arrow2* (arrow))
(setq *arrow3* (arrow))
(setq *arrow4* (arrow))

(send *arrow1* :newcoords (make-coords :pos (float-vector 387.328 8543.632 31356.63) :rpy (float-vector 3.084 0.161 3.03)))
(send *arrow2* :newcoords (make-coords :pos (float-vector 604.29 8661.698 31446.802) :rpy (float-vector -2.271 0.074 3.135)))
(send *arrow3* :newcoords (make-coords :pos (float-vector 642.44 8841.814 31426.53) :rpy (float-vector -1.613 -0.108 -3.134)))
(send *arrow4* :newcoords (make-coords :pos (float-vector 633.131 8900.09 31432.37) :rpy (float-vector 0.49 -1.566 1.207)))
(send *arrow* :newcoords (send *arrow1* :copy-worldcoords))

(objects (list *shelf-door* *arrow* *arrow1* *arrow2* *arrow3* *arrow4*))

(warn "please run (open) or (close) ~%")

;; いつかの計測では，棚の位置0度：429.913 8550.693 31453.22 / 3.027 0.086 3.054
;; 棚が90度くらい：648.19 8827.538 31446.995 / -1.691 0.058 -3.114> だったみたい．


(defun open ()
  (send *shelf-door* :angle-vector #f(90))
  (send *viewer* :draw-objects)
  (print (send *shelf-door* :handle))
  
  (warn "please run (close) ~%")
  )

(defun close ()
  (send *shelf-door* :angle-vector #f(0))
  (send *viewer* :draw-objects)
  (print (send *shelf-door* :handle))

  (warn "please run (open) ~%")
  )
