(ros::roseus "kitchen_3dbbox_detector")

;; TODO 引数とかで指定できるようなちゃんとした形で書く！！
(ros::load-ros-manifest "jsk_recognition_msgs")
(ros::advertise "/dynamic_attention_clipper/input/box" jsk_recognition_msgs::BoundingBox 1)

(defun test-cup1 ()
  (let (hdr pose dims msg)
    (setq hdr (instance std_msgs::header :init
                        :stamp (ros::time-now) :frame_id "base_link"))
    (setq pose (instance geometry_msgs::pose :init
                         :position (instance geometry_msgs::point :init :x 0.8 :y -0.07 :z 0.8)))
    (setq dims (instance geometry_msgs::vector3 :init
                         :x 0.2 :y 0.2 :z 0.2))
    (setq msg (instance jsk_recognition_msgs::BoundingBox :init
                        :header hdr
                        :pose pose
                        :dimensions dims))
    (ros::publish "/dynamic_attention_clipper/input/box" msg)    
    )
  )

