#!/usr/bin/env roseus

(load "package://jsk_2022_10_egg_dishes/euslisp/pr2_cook_tmp.l")


(defun reset-manip-pose ()
  (send *robot* :reset-manip-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  )

(defun check-pot-place-before ()
  (send *ri* :stop-grasp :larm :wait t)

  (reset-manip-pose)

  (send *robot* :larm :angle-vector #f(18.2499 59.1407 82.752 -95.0231 -78.2344 -64.0696 75.1862))
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (send *robot* :larm :angle-vector #f(10.0796 51.754 65.176 -84.298 -78.5327 -57.4061 69.7143))
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  )

(defun check-pot-place-after ()
  (send *ri* :stop-grasp :larm :wait t)

  (send *robot* :larm :angle-vector #f(18.2499 59.1407 82.752 -95.0231 -78.2344 -64.0696 75.1862))
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose)
  )


(defun do-exec ()
  ;; subscribeして沸騰していたら，pourを実行するプログラムを書く
  )

(defun pour-egg-to-pot ()
  (load-cook-pour-file :file_name "cook_pour_bowl_to_pot_data_20221027_02.l")
  (cook-pick-and-pour-short-replay-test)
  (reset-manip-pose)
  )

(defun stop-ih ()
  (load-cook-file :file_name "cook_data_stop-ih_20221027_01.l")
  (cook-replay-once)
  (reset-manip-pose)
  )
