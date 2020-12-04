(load "models/arrow-object.l")
(setq *arrow1* (arrow))
(setq *arrow2* (arrow))
(setq *arrow3* (arrow))

(load "red-cup.l")
(setq *red-cup* (red-cup))
(send *red-cup* :translate #f(100 0 0) :world)

(load "dispenser.l")
(setq *dispenser* (dispenser))
(send *dispenser* :translate #f(0 0 0) :world)

(load "solt.l")
(setq *solt* (solt))
(send *solt* :translate #f(-100 0 0) :world)

;; (send *arrow1* :newcoords (send (send *red-cup* :attention-attention1) :copy-worldcoords))

(send *arrow2* :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))
(send *arrow1* :newcoords (send (send *dispenser* :attention-attention0) :copy-worldcoords))

;; (send *arrow1* :newcoords (send (send *solt* :handle-handle0) :copy-worldcoords))
;; (send *arrow2* :newcoords (send (send *solt* :attention-attention0) :copy-worldcoords))

(objects (list *solt* *dispenser* *red-cup* *arrow1* *arrow2*))
