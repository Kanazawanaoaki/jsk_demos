(load "models/iemon-object.l")
(setq *iemon* (iemon))

(load "models/arrow-object.l")
(setq *axis* (arrow))
(send *axis* :move-to (send *iemon* :copy-worldcoords) :world)

(send *axis* :move-to (send *iemon* :worldcoords) :world)
(send *axis* :translate #f(-80 0 40) :world)


(setq *axis2* (arrow))
(send *axis2* :move-to (send *iemon* :worldcoords) :world)
(send *axis2* :locate #f(0 0 -55))
(send *axis2* :rotate (deg2rad -90) :y)

(objects (list *iemon* *axis* *axis2*))
