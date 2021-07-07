(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :eng2-scene "package://jsk_maps/src/eng2-scene.l")
(require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")
(defparameter *detection-topic* "/ObjectDetection")


(unless (boundp '*pr2*) (pr2-init))
(unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))
(objects (list *scene* *pr2*))
(send *irtviewer* :look-all *pr2*)


(defun update-pr2 ()
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  (send *pr2* :copy-worldcoords)
  (send *irtviewer* :look-all *pr2*)
  (send *viewer* :draw-objects)
  )

(warn "pelase run (update-pr2) ~%")
