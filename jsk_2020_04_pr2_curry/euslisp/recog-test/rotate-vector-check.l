(setq *vec* (float-vector 0.171743050249 0.729237656249 0.532461521205))
;; (setq *vec* (float-vector 0.562998809359 0.912793348004 0.370785497663))
;; (setq *vec* (float-vector 3.39132360172 0.525302267649 -2.95254670472))

;; (setq *vec* (float-vector -1.12208245809 -4.1886704708 -2.33491272863))
;; (setq *vec* (float-vector -0.753523459738 -2.12361174891 -2.74528444056))
;; (setq *vec* (float-vector 1.09410280265 -1.58661860077 -3.35851175947))

(defun rcup-coords ()
  (setq *co* (make-coords :pos (float-vector 474.868 8900.116 31134.418) :rpy (float-vector 1.569 3.188e-05 -1.57)))
  )

(defun mcup-coords ()
  (setq *co* (make-coords :pos (float-vector 474.868 8900.116 31134.418) :rpy (float-vector 3.141 0.75 4.036e-05)))
  )


(defun check ()
  (print (send *co* :rotate-vector *vec*))
  )


(mcup-coords)
(check)
