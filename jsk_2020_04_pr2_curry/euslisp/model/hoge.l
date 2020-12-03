(load "red-cup.l")
(setq *red-cup* (red-cup))
(send *red-cup* :translate #f(100 0 0) :world)

(load "dispenser.l")
(setq *dispenser* (dispenser))
(send *dispenser* :translate #f(0 0 0) :world)

(load "solt.l")
(setq *solt* (solt))
(send *solt* :translate #f(-100 0 0) :world)

(objects (list *solt* *dispenser* *red-cup*))
