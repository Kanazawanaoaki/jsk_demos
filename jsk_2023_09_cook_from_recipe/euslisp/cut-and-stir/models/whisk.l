(defun point-mul (point x y z)
  (float-vector (* (elt point 0) x) (* (elt point 1) y) (* (elt point 2) z)))

(defun make-prolate-spheroid (minor-axis major-axis)
  (let (b1 b2 x-scale v-list)
    (setq x-scale (/ (float major-axis) (float minor-axis)))
    (setq b1 (make-sphere minor-axis))
    (setq v-list (list))
    (dolist (point (send b1 :vertices)) (setq v-list (append v-list (list (point-mul point x-scale 1 1)))))
    (setq b2 (convex-hull-3d v-list))
    b2))

(defclass whisk-object
  :super cascaded-link
  :slots (
          attention0
          ))

(defmethod whisk-object
  (:init
   (&rest args &key (name "whisk") (pos (float-vector 0 0 0)) (rot (unit-matrix 3)) &allow-other-keys)
   (let (link1 b1 b2)
     (send-super* :init :name name args)

     ;; definition of link
     (setq b1 (make-prolate-spheroid 30 70))
     (setq b2 (make-cube 160 25 15))

     (send b1 :locate #f(70 0 0))
     (send b2 :locate #f(-80 0 0))

     (send b1 :assoc b2)

     ;; (send b1 :set-color :BurlyWood)
     ;; (send b2 :set-color :BurlyWood)

     (setq link1 (instance bodyset-link :init (make-cascoords) :bodies (list b1 b2) :weight 1 :centroid (float-vector 0.0 0.0 0.0) :inertia-tensor #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))


     ;; definition of assoc
     (send self :assoc link1)

     ;; definition of end-coords

     ;; definition of joint

     ;; definition of :handle

     ;; definition of :attention
     (setq attention0 (make-cascoords :pos (float-vector 140 0 0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0)) :name "attention0"))
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

(defun whisk (&rest args) (instance* whisk-object :init args))
