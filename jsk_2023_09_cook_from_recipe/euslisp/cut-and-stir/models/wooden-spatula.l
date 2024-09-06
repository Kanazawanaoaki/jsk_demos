(defclass wooden-spatula-object
  :super cascaded-link
  :slots (
          attention0
          ))

(defmethod wooden-spatula-object
  (:init
   (&rest args &key (name "wooden-spatula") (pos (float-vector 0 0 0)) (rot (unit-matrix 3)) &allow-other-keys)
   (let (link1 b1 b2)
     (send-super* :init :name name args)

     ;; definition of link
     (setq b1 (make-prism (list #f(125 33 0) #f(60 30 0) #f(0 10 0) #f(0 -10 0) #f(60 -30 0) #f(125 -33 0)) 8))
     (setq b2 (make-cube 170 20 8))

     (send b2 :locate #f(-85 0 0))
     (send b1 :locate #f(0 0 -4))

     (send b1 :assoc b2)

     (send b1 :set-color :BurlyWood)
     (send b2 :set-color :BurlyWood)

     (setq link1 (instance bodyset-link :init (make-cascoords) :bodies (list b1 b2) :weight 1 :centroid (float-vector 0.0 0.0 0.0) :inertia-tensor #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))


     ;; definition of assoc
     (send self :assoc link1)

     ;; definition of end-coords

     ;; definition of joint

     ;; definition of :handle

     ;; definition of :attention
     (setq attention0 (make-cascoords :pos (float-vector 125 0 0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0)) :name "attention0"))
     (send link1 :assoc attention0)

     ;; init-ending
     (setq links (list link1))
     (send self :init-ending)
     (send self :move-to (make-coords :pos pos :rot rot))
     (send-all links :worldcoords)

     self))

  (:attention (&rest args) (forward-message-to-all (list attention0) args))
  (:attention-attention0 (&rest args) (forward-message-to-all attention0 args))
  )

(defun wooden-spatula (&rest args) (instance* wooden-spatula-object :init args))
