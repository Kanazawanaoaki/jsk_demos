;; set potato
(load "../../model/potato-new-type.l")


(setq *potato* (potato :w 90 :l 60 :h 60))
(send *potato* :cut)

(send p4 :dissoc p7)
(send p7 :translate #f(0 0 -100) :world)
(send p4 :dissoc p8)
(send p8 :translate #f(0 0 -100) :world)

(send p4 :dissoc p1)
(send p4 :dissoc p2)
(send p4 :dissoc p3)  
(send p1 :translate #f(0 100 0) :world)
(send p2 :translate #f(0 100 0) :world)
(send p3 :translate #f(0 100 0) :world)

(load "models/arrow-object.l")
(setq *arrow* (arrow))

(send *arrow* :newcoords (send *cut-point-4* :copy-worldcoords))

(send p1 :translate #f(0 0 50) :world)
(send p3 :translate #f(0 0 -50) :world)

(objects (list *arrow* *potato*))
