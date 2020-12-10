(load "models/arrow-object.l")
(setq *arrow1* (arrow))
(setq *arrow2* (arrow))
(setq *arrow3* (arrow))

(load "white-dish.l")
(setq *white-dish* (white-dish))
(send *white-dish* :translate #f(100 0 0) :world)

(send *arrow1* :newcoords (send (send *white-dish* :attention-attention0) :copy-worldcoords))

(objects (list *white-dish* *arrow1*))
