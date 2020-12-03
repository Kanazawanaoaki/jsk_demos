;; WIP!!!

(defclass dispenser-object
  :super cascaded-link
  :slots (handle0
	  attention0
	  attention1
	  ))

(defmethod dispenser-object
  (:init
   (&rest args &key (name "dispenser") (pos (float-vector 0 0 0)) (rot (unit-matrix 3)) &allow-other-keys)
   (let (link1 b1 b2 b3 b4 b5 b6 b7 b8)
     (send-super* :init :name name args)

     ;; definition of link
     (setq b1 (make-cylinder 45 110))

     (send b1 :set-color :White)
     
     (setq link1 (instance bodyset-link :init (make-cascoords) :bodies (list b1) :weight 1 :centroid (float-vector 0.0 0.0 0.0) :inertia-tensor #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))


     ;; definition of assoc
     (send self :assoc link1)

     ;; definition of end-coords

     ;; definition of joint

     ;; definition of :handle
     (setq handle0 (make-cascoords :pos #f(0 75 70) :rpy #f(3.14 0 0) :name "handle0"))
     (send link1 :assoc handle0)

     ;; definition of :attention
     (setq attention0 (make-cascoords :pos #f(0 -50 110) :name "attention0"))
     (send link1 :assoc attention0)
     (setq attention1 (make-cascoords :pos #f(0 0 110) :rpy #f(-1.57 0 0) :name "attention1"))
     (send link1 :assoc attention1)
    
     ;; init-ending 
     (setq links (list link1))
     (send self :init-ending)
     (send self :move-to (make-coords :pos pos :rot rot))
     (send-all links :worldcoords)

     self))

  (:handle (&rest args) (forward-message-to-all (list  handle0) args))
  (:handle-handle0 (&rest args) (forward-message-to handle0 args))
  (:attention (&rest args) (forward-message-to-all (list  attention0 attention1) args))
  (:attention-attention0 (&rest args) (forward-message-to attention0 args))
  (:attention-attention1 (&rest args) (forward-message-to attention1 args))
  )

(defun dispenser (&rest args) (instance* dispenser-object :init args))
