(defclass stove-kitchen-plane-object
  :super cascaded-link
  :slots (
      attention0
      attention1
      attention2
      attention3
      ))

(defmethod stove-kitchen-plane-object
  (:init
   (&rest args &key (name "stove-kitchen-plane") (pos (float-vector 0 0 0)) (rot (unit-matrix 3)) (cube-x 605) (cube-y 1030) (cube-z 10) &allow-other-keys)
   (let (link1 b1)
     (send-super* :init :name name args)

     ;; definition of link
     (setq b1 (make-cube cube-x cube-y cube-z))
     (setq b2 (make-cube cube-x cube-y cube-z))

     (send b2 :locate (float-vecto r0 0 10))
     (send b2 :set-color :Black)

     (setq link1 (instance bodyset-link :init (make-cascoords) :bodies (list b1) :weight 1 :centroid (float-vector 0.0 0.0 0.0) :inertia-tensor #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))
     (setq link2 (instance bodyset-link :init (make-cascoords) :bodies (list b1) :weight 1 :centroid (float-vector 0.0 0.0 0.0) :inertia-tensor #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))

     ;; definition of assoc
     (send self :assoc link1)

     ;; definition of end-coords

     ;; definition of joint

     ;; definition of :handle

     ;; definition of :attention
     (setq attention0 (make-cascoords :pos (float-vector (/ cube-x 2) (/ cube-y 2) (/ cube-z 2)) :rpy (float-vector 0 0 0) :name "attention0"))
     (send link1 :assoc attention0)
     (setq attention1 (make-cascoords :pos (float-vector (/ cube-x 2) (- (/ cube-y 2)) (/ cube-z 2)) :rpy (float-vector 0 0 0) :name "attention1"))
     (send link1 :assoc attention1)
     (setq attention2 (make-cascoords :pos (float-vector (- (/ cube-x 2)) (/ cube-y 2) (/ cube-z 2)) :rpy (float-vector 0 0 0) :name "attention2"))
     (send link1 :assoc attention2)
     (setq attention3 (make-cascoords :pos (float-vector (- (/ cube-x 2)) (- (/ cube-y 2)) (/ cube-z 2)) :rpy (float-vector 0 0 0) :name "attention3"))
     (send link1 :assoc attention3)

     ;; init-ending
     (setq links (list link1))
     (send self :init-ending)
     (send self :move-to (make-coords :pos pos :rot rot))
     (send-all links :worldcoords)

     self))

  (:attention (&rest args) (forward-message-to-all (list attention0 attention1 attention2 attention3) args))
  (:attention-attention0 (&rest args) (forward-message-to-all attention0 args))
  (:attention-attention1 (&rest args) (forward-message-to-all attention1 args))
  (:attention-attention2 (&rest args) (forward-message-to-all attention2 args))
  (:attention-attention3 (&rest args) (forward-message-to-all attention3 args))
  )

(defun stove-kitchen-plane (&rest args) (instance* stove-kitchen-plane-object :init args))
