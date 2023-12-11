(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :pr2-cook-tmp "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")

(setq *initial-head-neck-y* 0.0)
(setq *initial-head-neck-p* 50.0)

(defun set-objects-on-table (&key (object-name "ボウル1") (arm :rarm))
  (let (pre-set-avs
        pre-set-val
        set-coords
        )
    (cond
     ((string= object-name "ボウル1")
      (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041) #f(-45.3343 3.47451 -56.4107 -109.672 -99.5375 -114.592 104.776)))
      (setq pre-set-val #f(-50 0 -50))
      (setq set-coords (make-coords :pos #f(600.991 -365.044 878.981) :rpy #f(-0.496 1.352 -2.114)))
      )
     ((string= object-name "ボウル0")
      (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)))
      (setq pre-set-val #f(0 0 -100))
      (setq set-coords (make-coords :pos #f(760.846 -230.582 846.976) :rpy #f(-0.353 1.158 -1.828)))
      )
     ((string= object-name "ボウル0") ;; ここからTODO
      (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)))
      (setq pre-set-val #f(0 0 -100))
      (setq set-coords (make-coords :pos #f(760.846 -230.582 846.976) :rpy #f(-0.353 1.158 -1.828)))
      )
     )
  )

(defun set-pot-on-stove (&key (arm :larm) (object-name "鍋"))
  (if (equal arm :larm)
      (progn
        (reset-manip-pose :arm :larm :time 2000)

        (send *pr2* :larm :angle-vector #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (send *ri* :stop-grasp :larm :wait t)

        (cond
         ((string= object-name "鍋")
          (send *pr2* :larm :angle-vector #f(15.0755 56.5882 65.6859 -96.6074 -98.943 -62.4489 -88.545))
          )
         ((string= object-name "フライパン")
          (send *pr2* :larm :angle-vector #f(18.8234 64.1057 72.9717 -100.133 -92.8479 -64.159 -87.0742))
          )
         )
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)
        )
    )

  (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" object-name))
  (ok-wait)

  (if (equal arm :larm)
      (progn
        (send *ri* :stop-grasp :larm :wait t)

        (send *pr2* :larm :angle-vector #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (reset-manip-pose :arm :larm :time 2000)
        )
    )
  )

(defun rotate-knob (&rest args &key (deg 30) (arm :larm) &allow-other-keys)
  ;; rotate
  (let (av avs tms (ik-target (send (send *pr2* arm :end-coords) :copy-worldcoords)))
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
    (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

    (if (> deg 0)
      (progn
        (dotimes (i (/ deg 10))
          (send ik-target :rotate (deg2rad 10) :x)
          (send *pr2* arm :inverse-kinematics
                (send ik-target :copy-worldcoords)
                :rotation-axis t
                :debug-view nil)
          (setq av (send *pr2* :angle-vector))
          (setq avs (append avs (list av)))
          (setq tms (append tms (list 200)))
          ))
      (dotimes (i (/ (* deg -1) 10))
        (send ik-target :rotate (deg2rad -10) :x)
        (send *pr2* arm :inverse-kinematics
              (send ik-target :copy-worldcoords)
              :rotation-axis t
              :debug-view nil)
        (setq av (send *pr2* :angle-vector))
        (setq avs (append avs (list av)))
        (setq tms (append tms (list 200)))
        )
      )
    (send *ri* :angle-vector-sequence avs tms)
    (send *ri* :wait-interpolation)
    )
  )


(defun start-ih (&key (left nil) (max-power nil))
  (stop-ih :left left :only-stop nil)

  ;; grasp knob
  (send *ri* :move-gripper :rarm 0.08)

  (let ((ik-target))
    (setq ik-target (make-coords :pos #f(540 -33.562 705) :rpy #f(0.0 0.0 -1.5708))) ;; right ;; (float-vector 636 -183 698)
    (send ik-target :rotate (deg2rad 90) :x)
    ;; (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :rarm :inverse-kinematics ;; left TODO
          (send ik-target :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    )

  (send *ri* :start-grasp :rarm :wait t :gain 100)
  ;; rotate
  (rotate-knob :deg 30 :arm :rarm)
  (if max-power
      (progn
        (unix:sleep 1)
        (rotate-knob :deg 60 :arm :rarm)
        ))
  ;; release
  (send *ri* :stop-grasp :rarm :wait t)
  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose :arm :rarm :time 2000)
  )

(defun stop-ih (&key (left nil) (only-stop t))
  (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

  (reset-manip-pose :arm :rarm :time 2000)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :rarm :wait t)

  (let (ik-target)
    (if left
        (progn
          (send *pr2* :rarm :angle-vector #f(-10.3805 65.2155 -51.4302 -73.631 122.477 -46.0296 -19.6429)) ;; left TODO
          )
      (progn
        ;; (send *pr2* :rarm :angle-vector #f(-32.9823 60.3212 -73.0221 -74.5233 120.244 -39.7369 -5.03581)) ;; #f(-31.9892 63.9795 -66.939 -75.7959 118.513 -36.3796 -8.94601))
        ;; (setq ik-target (make-coords :pos #f(527.887 -33.562 705) :rpy #f(0.0 0.0 -1.5708)))
        (setq ik-target (make-coords :pos #f(537.887 -33.562 705) :rpy #f(0.0 0.0 -1.5708)))
        (send *pr2* :rarm :inverse-kinematics
              ik-target
              :rotation-axis t
              :revert-if-fail nil)
        ))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)


  (send *pr2* :rarm :move-end-pos #f(10 0 0))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (when only-stop
    (reset-manip-pose :arm :rarm :time 2000)
    )
  )

