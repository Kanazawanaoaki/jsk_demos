(load "../../model/potato-new-type.l")

;; (setq *potato* (potato :w 90 :l 60 :h 60))
;; (send *potato* :cut)

;; ;; (send p1 :locate #f(0 0 100))
;; ;; (send p3 :locate #f(0 0 -100))

;; (objects (list *potato*))

(load "models/arrow-object.l")
(setq *arrow* (arrow))

(setq *potato* (potato :w 90 :l 60 :h 60))
(send *potato* :peel)

(send *potato* :locate #f(0 100 0))

(send p1 :locate #f(0 0 100))
(send p3 :locate #f(0 0 -100))


(send *arrow* :newcoords (send *cut-point-2* :copy-worldcoords))


(objects (list *potato* *arrow*))
