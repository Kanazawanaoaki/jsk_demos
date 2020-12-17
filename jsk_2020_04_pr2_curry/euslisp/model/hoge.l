(load "models/arrow-object.l")
(setq *arrow1* (arrow))
(setq *arrow2* (arrow))
(setq *arrow3* (arrow))

(load "curry-dish.l")
(setq *curry-dish* (curry-dish))
(send *curry-dish* :translate #f(100 0 0) :world)

(send *arrow1* :newcoords (send (send *curry-dish* :attention-attention0) :copy-worldcoords))

(objects (list *curry-dish* *arrow1*))
