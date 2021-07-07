(load "../../model/carrot-ellipsoid-model.l")
;; (setq *carrot* (carrot :w 160 :l 40 :h 40))

(setq *carrot* (carrot :w 100 :l 60 :h 60))


(send *carrot* :cut)

(send c1 :locate #f(0 0 100))
(send c3 :locate #f(0 0 -100))

(objects (list *carrot*))
