#!/usr/bin/env roseus

(load "package://pr2eus/pr2-interface.l")
(pr2-init)


(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun record-av ()
  (setq *avs* (list))
  (setq *tms* (list))
  
  (do-until-key 
   (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
   (setq av (send *pr2* :angle-vector))
   (setq *avs* (append *avs* (list av)))
   (setq *tms* (append *tms* (list 600)))
   (unix::usleep 500000)
   )
  (print *avs*)
  )


(defun play-av (avs tms)
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )


