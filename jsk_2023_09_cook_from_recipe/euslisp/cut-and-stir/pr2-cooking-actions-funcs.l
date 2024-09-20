#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2_cut_food.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/73b2-kitchen-coords.l")

;; set global variable
(setq *debug-flag* t)
(setq *s-time* 3)

(setq *x-thre* -15)
(setq *cb-flag* nil)

(defun pr2-cook-init (&key (reset-obj-cds t) (init-cds t) (type :curry) (spot "kitchen"))
  ;; init

  (cond
   ((equal spot "kitchen")
    ;; set global coords
    (when init-cds
      (73b2-kitchen-coords-init :type type))
    ;; set tools
    (when reset-obj-cds
      (73b2-kitchen-obj-init :type type))
    )
   ((equal spot "stove")
    ;; set global coords
    (when init-cds
      (73b2-stove-coords-init :type type))
    ;; set tools
    (when reset-obj-cds
      (73b2-stove-obj-init :type type))
    )
   )

  (objects *view-objects*)
  )

(warn "~%  Please run (pr2-cook-init :type :curry :spot kitchen) ~%")

;; update funcs
(defun set-tool-on-table (&key (object-name "knife") (arm :rarm) (action-mode :set) (spot-name "kitchen") (use-cds-offset nil))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        (adj-target-cds)
        (obj-coords)
        )
    (cond
     ((and (string= object-name "knife") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 358.964)))
      (setq pre-set-val #f(-50 0 -100))

      ;; calc from defined coords
      (send *arrow* :newcoords (send *knife-coords* :copy-worldcoords))
      (send *arrow* :translate #f(-12 0 0))
      (send *arrow* :rotate (deg2rad -90) :x)
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *knife-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "potato peeler") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 358.964)))
      (setq pre-set-val #f(-50 0 -100))

      ;; calc from defined coords
      (send *arrow* :newcoords (send *potato-peeler-coords* :copy-worldcoords))
      (send *arrow* :rotate (deg2rad -90) :x)
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *potato-peeler-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "peeler") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 358.964)))
      (setq pre-set-val #f(-50 0 -100))

      ;; calc from defined coords
      (send *arrow* :newcoords (send *peeler-coords* :copy-worldcoords))
      (send *arrow* :rotate (deg2rad -90) :x)
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *peeler-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "gray bowl") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-39.4916 -5.60379 -51.4586 -70.0476 -75.5379 -114.544 397.394)))
      (setq pre-set-val #f(-147 -23 7)) ;; for upper #f(0 0 150) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *gray-bowl-kitchen-coords* (make-coords :pos #f(-101.233 0.0 53.999) :rpy #f(0.265 1.405 -1.282))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *gray-bowl-kitchen-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "gray bowl") (string= spot-name "stove") (equal arm :rarm)) ;; TODO
      (setq pre-set-avs (list #f(-39.4916 -5.60379 -51.4586 -70.0476 -75.5379 -114.544 397.394)))
      (setq pre-set-val #f(-147 -23 7)) ;; for upper #f(0 0 150) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *gray-bowl-stove-coords* (make-coords :pos #f(-89.819 12.851 40.629) :rpy #f(0.478 1.218 -0.929))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *gray-bowl-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "green bowl") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782))) ;; for green bowl, upper outside
      (setq pre-set-val #f(-100 0 0))

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *green-bowl-stove-coords* (make-coords :pos #f(-57.768 20.693 22.929) :rpy #f(0.115 1.25 -1.37))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *green-bowl-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "green bowl") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(48.7972 1.40098 47.7424 -89.0343 68.0991 -99.506 -53.0755))) ;; TODO
      (setq pre-set-val #f(-100 0 0)) ;; for upper #f(0 0 150) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *green-bowl-stove-coords* (make-coords :pos #f(-57.768 20.693 22.929) :rpy #f(0.115 1.25 -1.37))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *green-bowl-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "oil dispenser") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(48.8499 -11.5118 87.4519 -117.546 -193.632 -67.0977 267.029))) ;; (make-coords :pos #f(570.089 255.41 1143.02) :rpy -0.025 0.057 3.124)
      ;; (setq pre-set-val #f(-50 0 -100))
      (setq pre-set-val #f(-5.697 1.756 -99.822)) ;; for upper #f(0 0 100) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *oil-dispenser-stove-coords* (make-coords :pos #f(-9.925 5.389 113.022) :rpy #f(-0.023 0.057 3.124))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *oil-dispenser-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "spatula") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-41.0354 31.325 -34.2869 -99.4442 -158.179 -54.5975 103.313)))
      ;; (setq pre-set-val #f(-50 0 -100))
      (setq pre-set-val #f(-100 0 -100)) ;; for upper

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *spatula-stove-coords* (make-coords :pos #f(-160 0 0) :rpy #f(0 0 -1.571))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *spatula-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "frying pan") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(25.83 -4.49773 82.9127 -114.765 -190.225 -92.4874 -86.8266)
                              #f(20.277 8.77317 68.6259 -48.2159 -262.701 -99.5498 53.6745)
                              ))
      (setq pre-set-val #f(-150 0 0)) ;; for upper

      ;; calc from defined coords
      (setq obj-coords (send *pan-coords* :copy-worldcoords))
      (send *arrow* :newcoords (calc-coords-from-rel obj-coords (make-coords :pos #f(-184.952 13.937 20.367) :rpy #f(-0.361 1.264 2.752))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send obj-coords :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     (t
      (format t "Sorry, object-name ~A, spot-name ~A, arm ~A is not defined now !!!~%" object-name spot-name arm)
      (return-from set-tool-on-table nil)
      )
     )

    (if use-cds-offset
        (setq adj-target-cds (adjust-cds-with-spot set-target-coords spot-name))
      (setq adj-target-cds (send set-target-coords :copy-worldcoords))
      )
    (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm arm :action-mode action-mode :object-name object-name)

    ;; TODO add dissoc object
    ))

(defun hold-pot-on-stove (&key (arm :larm) (object-name "pot") (action-mode :hold) (spot-name "stove") (use-cds-offset nil))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        adj-target-cds
        )
    (cond
     ((and (string= object-name "pot") (string= spot-name "stove") (equal arm :larm))
      ;; (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102)))
      (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142  265.39)))
      (setq pre-set-val #f(-100 0 0))

      ;; calc from defined coords
      ;; (send set-target-coords :newcoords (make-coords :pos #f(699.076 178.059 947.711) :rpy #f(0.012 -0.62 3.14)))
      (send *arrow* :newcoords (calc-coords-from-rel *pot-coords* (make-coords :pos #f(-180.924 8.059 107.711) :rpy (float-vector 0.012 -0.62 pi))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *pot-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "frying pan") (string= spot-name "stove") (equal arm :larm))
      ;; (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102)))
      (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 265.39)))
      (setq pre-set-val #f(-100 0 0))

      ;; calc from defined coords
      ;; (send set-target-coords :newcoords (make-coords :pos #f(657.029 -101.483 899.763) :rpy #f(0.056 -0.405 3.04)));; TODO calc from object coords
      (send *arrow* :newcoords (calc-coords-from-rel *pan-coords* (make-coords :pos #f(-222.971 8.517 59.763) :rpy (float-vector 0.056 -0.405 3.04))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *pan-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     (t
      (format t "Sorry, object-name ~A, spot-name ~A, arm ~A is not defined now !!!~%" object-name spot-name arm)
      (return-from hold-pot-on-stove nil)
      )
     )
    (if use-cds-offset
        (setq adj-target-cds (adjust-cds-with-spot set-target-coords spot-name))
      (setq adj-target-cds (send set-target-coords :copy-worldcoords))
      )
    (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm arm :action-mode action-mode :object-name object-name)
    ))

(defun release-pot-on-stove (&key (arm :larm) (use-cds-offset nil) (reset-pose-end t))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        adj-target-cds
        )
    (cond
     ((equal arm :larm)
      ;; (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102)))
      (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 265.39)))
      (setq pre-set-val #f(-100 0 0))

      (potentio-vector :head-p 50.0 :head-y 0.0)
      (send set-target-coords :newcoords (send (send *pr2* arm :end-coords) :copy-worldcoords))
      )
     (t
      (format t "Sorry, arm ~A is not defined now !!!~%" arm)
      (return-from release-pot-on-stove nil)
      )
     )

    (if use-cds-offset
        (setq adj-target-cds (adjust-cds-with-spot set-target-coords "stove"))
      (setq adj-target-cds (send set-target-coords :copy-worldcoords))
      )
    (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm arm :action-mode :release :object-name "pot" :reset-pose-end reset-pose-end)
    ))


;; pour
(defun add-oil-pre ()
  ;; この辺りはreachに置き換えられるか？

  ;; dispenserを位置に
  (send *pr2* :larm :move-end-pos #f(100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world) ;;fix
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world) ;;fix
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 120) :world)
  ;; (send *arrow* :rotate (deg2rad -90) :x)
  ;; (send *arrow* :rotate (deg2rad -90) :y :world)
  (send *arrow* :rotate (deg2rad 90) :y)
  (send *arrow* :rotate (deg2rad -90) :x)

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :link-list (list
                    (send *pr2* :larm))
        :move-target (send *oil-dispenser* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;右腕をセットしておく この辺りは:graspか:reachで表現できるはず．
  ;; (before-receive-rarm)
  (send *pr2* :rarm :angle-vector #f(-37.8868 -20.239 -85.7141 -64.0592 312.721 -87.1625 -148.994))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 右腕をセットする位置
  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  ;; (send *arrow* :translate #f(0 0 80) :world)
  ;; (send *arrow* :rotate (deg2rad 90) :z :world)

  (send *arrow* :translate #f(0 0 70) :world)
  ;; (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *arrow* :rotate (deg2rad 45) :z :world)

  ;; (send *arrow* :translate #f(0 100 80) :world)
  ;; (send *arrow* :translate #f(0 -100 80) :world) ;; fix
  (send *arrow* :translate #f(-100 0 -50) :local) ;; fix v2
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)

  ;; (send *arrow* :translate #f(0 -100 -80) :world)
  ;; (send *arrow* :translate #f(0 100 -80) :world) ;; fix
  (send *arrow* :translate #f(100 0 50) :local) ;; fix v2
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  (warn "please run (add-oil) ~%")
  )

(defun add-oil ()
  ;; (send *ri* :move-gripper :larm 0.04)
  (send *ri* :start-grasp :larm :gain 0.05 :wait t)
  (unix:sleep 3)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (after-oil) ~%")
  )

(defun add-oil-post ()
  ;; (if (not (eql (send *oil-dispenser* :parent) nil))
  ;;     (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (dissoc-object *oil-dispenser*)
  (send *pr2* :rarm :end-coords :assoc *oil-dispenser*)

  ;; 上にして持ち替える
  ;; 回転のために左手を引く
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  ;; (send *arrow* :translate #f(150 0 0) :world)
  (send *arrow* :translate #f(-150 0 0) :world) ;;fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  ;; 回転させる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :x)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  ;; IK が解けるように右腕を少し下げる
  (send *arrow* :translate #f(0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 左腕で再びつかむ
  ;; (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  ;; (send *arrow* :rotate (deg2rad 180) :z)
  (send *arrow* :newcoords (calc-coords-from-rel *oil-dispenser* (make-coords :pos #f(-9.925 5.389 113.022) :rpy #f(-0.023 0.057 3.124))))
  ;; (send *arrow* :rotate (deg2rad 180) :z)
  (send *arrow* :rotate (deg2rad 90) :z) ;; fix v2 because larm end-effector angle is changed

  ;; (send *arrow* :translate #f(100 0 0) :world)
  (send *arrow* :translate #f(-100 0 0) :world) ;;fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(-100 0 0) :world)
  (send *arrow* :translate #f(100 0 0) :world) ;;fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)

  ;; (if (not (eql (send *oil-dispenser* :parent) nil))
  ;;     (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (dissoc-object *oil-dispenser*)
  (send *pr2* :larm :end-coords :assoc *oil-dispenser*)


  ;; 右腕を戻して左腕をplaceの前位置にする．
  (send *ri* :stop-grasp :rarm :wait t)
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  ;; (send *arrow* :translate #f(0 100 0) :world)
  (send *arrow* :translate #f(0 -100 0) :world) ;;fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (reset-rarm)
  (send *pr2* :rarm :angle-vector #f(-37.8868 -20.239 -85.7141 -64.0592 312.721 -87.1625 -148.994))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (reset-cook-pose :arm :rarm)

  (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  ;; (send *ri* :wait-interpolation)

  ;; (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (warn "please run (place-oil-dispenser) ~%")
  )

(defun add-oil-whole ()
  (add-oil-pre)
  (add-oil)
  (add-oil-post)
  )


;; ih
(defun rotate-knob (&rest args &key (deg 30) (arm :larm) &allow-other-keys)
  ;; rotate
  (potentio-vector)
  (let (av (avs (list)) (tms (list)) (ik-target (send (send *pr2* arm :end-coords) :copy-worldcoords)))
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
    (unless (equal avs (list))
      (send *ri* :angle-vector-sequence avs tms)
      (send *ri* :wait-interpolation)
      )
    )
  )

(defun ih-stove-action (&key (left nil)
                             (ih-action :start) ;; :start :stop :rotate
                             (with-rec nil) (use-cds-offset t)
                             (rotate-deg 0))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        adj-target-cds
        (push-length 10)
        )
    (if left
        (progn
          (setq pre-set-avs (list #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)))
          ;; (setq pre-set-val #f(-100 0 0))
          (setq pre-set-val #f(-30 0 0))
          (setq set-target-coords (make-coords :pos #f(645 -55 696.789) :rpy #f(-0.089 0.092 1.448)))
          )
      (progn
        ;; (setq pre-set-avs (list #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)))
        (setq pre-set-avs (list #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313))) ;; #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863) for old
        ;; (setq pre-set-val #f(-100 0 0))
        (setq pre-set-val #f(-30 0 0))
        (setq set-target-coords (make-coords :pos #f(645.029 -178.873 696.789) :rpy #f(-0.089 0.092 1.448)))
        ))
    (if use-cds-offset
        (setq adj-target-cds (adjust-cds-with-spot set-target-coords "stove"))
      (setq adj-target-cds (send set-target-coords :copy-worldcoords))
      )

    (if (or (equal ih-action :stop) (equal ih-action :start))
        (progn
          (send adj-target-cds :translate (float-vector push-length 0 0) :local)
          (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm :rarm :action-mode :push :object-name "ih stove")
          (send adj-target-cds :translate (float-vector (- push-length) 0 0) :local)
          )
      )

    (if (or (equal ih-action :start) (equal ih-action :rotate))
        (progn
          (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm :rarm :action-mode :hold :object-name "ih stove")
          (if (equal ih-action :start)
              (progn
                ;; rotate
                (rotate-knob :deg 30 :arm :rarm)
                ))
          (rotate-knob :deg rotate-deg :arm :rarm)
          (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm :rarm :action-mode :release :object-name "ih stove")
          ))
    (reset-cook-pose :arm :rarm)
    )
  )

;; water
(defun sink-lever-rec ()
  (let ((rec-coords)
        (rec-to-target-offset)
        (grasp-cds))
    ;; (setq rec-to-target-offset (make-coords :pos #f(330.658 123.566 236.368) :rpy #f(-1.215 0.72 0.426))) ;; v1 ik fail
    (setq rec-to-grasp-offset (make-coords :pos #f(336.154 125.843 243.1) :rpy #f(-1.204 0.722 0.445)))
    (setq rec-to-faucet-offset (make-coords :pos #f(342.957 118.145 345.331) :rpy #f(0.018 1.503 -3.13)))

    ;; rec sink landmark
    (reset-cook-pose :head-p 30 :arm :rarm)
    (unix::sleep 1)
    (setq rec-coords (k4a-check-detection "/point_pose_sink/ObjectDetection"))
    ;; (setq hoge (send rec-coords :copy-worldcoords))
    (format t "point_pose_sink result: ~A ~%" rec-coords)

    (setq grasp-cds (calc-coords-from-rel rec-coords rec-to-grasp-offset))
    (setq faucet-cds (calc-coords-from-rel rec-coords rec-to-faucet-offset))
    (publish-cds-tf-list (list grasp-cds faucet-cds))
    (setq *faucet-rec-coords* (send faucet-cds :copy-worldcoords))

    grasp-cds))

(defun sink-lever-test (&key (use-cds-offset nil) (with-rec t))
  (let (
        ;; (wait-rav-1 #f(-41.4059 32.4107 -50.5582 -112.849 -176.587 -63.8396 38.962)) ;; 手前の姿勢
        ;; (wait-rav-2 #f(-24.8704 3.91558 -78.0752 -40.0538 -31.1184 -40.1947 20.8712)) ;; 奥の姿勢
        (wait-rav-1 #f(-15.8895 46.2354 -3.87426 -115.597 190.444 -68.0734 -1.41295)) ;; 手前の姿勢 for upper
        (wait-rav-2 #f(-8.79278 18.6346 3.39867 -41.8748 246.993 -69.8632 31.6097)) ;; 奥の姿勢
        (rec-lever-cds)
        )

    (when with-rec
      (setq rec-lever-cds (sink-lever-rec))
      (reset-cook-pose :head-p 50 :arm :rarm)
      )

    (send *pr2* :rarm :angle-vector wait-rav-1)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    (send *pr2* :rarm :angle-vector wait-rav-2)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    (send *ri* :move-gripper :rarm 0.03 :effort (* 2000 0.03) :wait t)

    ;; set
    ;; off
    (if with-rec
        (setq target-coords (send rec-lever-cds :copy-worldcoords))
      (progn
        (setq now-coords (make-coords :pos #f(877.466 -25.883 1012.658) :rpy #f(0.794 0.215 -1.428)))
        (if use-cds-offset
            (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
          (setq target-coords (send now-coords :copy-worldcoords)))
        ))
    (send *pr2* :rarm :inverse-kinematics
          (send target-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :start-grasp :rarm :wait t)

    ;; on
    (if with-rec
        (progn
          (setq off-on-rel (make-coords :pos #f(0.634896 -34.6435 -12.8812) :rpy #f(0.207 0.246 0.267)))
          (setq target-coords (calc-coords-from-rel target-coords off-on-rel))
          )
      (progn
        ;; (setq now-coords (make-coords :pos #f(893.597 -17.28 1043.267) :rpy #f(0.539 0.466 -1.373)))
        (setq now-coords (make-coords :pos #f(895.364 -32.896 1044.233) :rpy #f(0.556 0.444 -1.265)))
        (if use-cds-offset
            (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
          (setq target-coords (send  now-coords :copy-worldcoords)))
        ))
    (send *pr2* :rarm :inverse-kinematics
          (send target-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (unix:sleep 1) ;; TODO なにか処理

    ;; off
    (if with-rec
        (setq target-coords (send rec-lever-cds :copy-worldcoords))
      (progn
        (setq now-coords (make-coords :pos #f(877.466 -25.883 1012.658) :rpy #f(0.794 0.215 -1.428)))
        (if use-cds-offset
            (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
          (setq target-coords (send  now-coords :copy-worldcoords)))
        ))
    (send *pr2* :rarm :inverse-kinematics
          (send target-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :move-gripper :rarm 0.03 :effort (* 2000 0.03) :wait t)

    (send *pr2* :rarm :angle-vector wait-rav-2)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    (send *pr2* :rarm :angle-vector wait-rav-1)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)
    ))


;; wrapper funcs
(defun receive-and-set-knife ()
  (set-tool-on-table :object-name "knife" :arm :rarm :action-mode :set :spot-name "kitchen" :use-cds-offset nil)
  )

(defun place-knife ()
  (set-tool-on-table :object-name "knife" :arm :rarm :action-mode :place :spot-name "kitchen" :use-cds-offset nil)
  )

(defun pick-up-knife ()
  (set-tool-on-table :object-name "knife" :arm :rarm :action-mode :pick-up :spot-name "kitchen" :use-cds-offset nil)

  (assoc-object-to-arm *knife* (calc-coords-from-rel *knife* (make-coords :pos #f(0 0 0) :rpy #f(0.0 0.0 -1.571))) :arm :rarm)
  )

(defun receive-and-set-peeler ()
  (set-tool-on-table :object-name "peeler" :arm :rarm :action-mode :set :spot-name "kitchen" :use-cds-offset nil)
  )

(defun place-peeler ()
  (set-tool-on-table :object-name "peeler" :arm :rarm :action-mode :place :spot-name "kitchen" :use-cds-offset nil)
  )

(defun pick-up-peeler ()
  (set-tool-on-table :object-name "peeler" :arm :rarm :action-mode :pick-up :spot-name "kitchen" :use-cds-offset nil)

  (assoc-object-to-arm *peeler* (calc-coords-from-rel *peeler* (make-coords :pos #f(0 0 0) :rpy #f(0.0 0.0 -1.571))) :arm :rarm)
  )

(defun receive-and-set-potato-peeler ()
  (set-tool-on-table :object-name "potato peeler" :arm :rarm :action-mode :set :spot-name "kitchen" :use-cds-offset nil)
  (set-object *potato-peeler* (send *potato-peeler-coords* :copy-worldcoords))
  )

(defun place-potato-peeler ()
  (set-tool-on-table :object-name "potato peeler" :arm :rarm :action-mode :place :spot-name "kitchen" :use-cds-offset nil)
  (set-object *potato-peeler* (send *potato-peeler-coords* :copy-worldcoords))
  )

(defun pick-up-potato-peeler ()
  (set-tool-on-table :object-name "potato peeler" :arm :rarm :action-mode :pick-up :spot-name "kitchen" :use-cds-offset nil)

  (assoc-object-to-arm *potato-peeler* (calc-coords-from-rel *potato-peeler* (make-coords :pos #f(0 0 0) :rpy #f(0.0 0.0 -1.571))) :arm :rarm)
  )

(defun receive-and-set-gray-bowl (&key (spot "kitchen")) ;; TODO add head
  (cond
   ((equal spot "kitchen")
    (set-tool-on-table :object-name "gray bowl" :arm :rarm :action-mode :set :spot-name spot :use-cds-offset nil)
    (set-object *gray-bowl* (send *gray-bowl-kitchen-coords* :copy-worldcoords))
    )
   ((equal spot "stove")
    (set-tool-on-table :object-name "gray bowl" :arm :rarm :action-mode :set :spot-name spot :use-cds-offset nil)
    (set-object *gray-bowl* (send *gray-bowl-stove-coords* :copy-worldcoords))
    )
   ))

(defun place-gray-bowl (&key (spot "kitchen"))
  (cond
   ((equal spot "kitchen")
    (set-tool-on-table :object-name "gray bowl" :arm :rarm :action-mode :place :spot-name spot :use-cds-offset nil)
    (set-object *gray-bowl* (send *gray-bowl-kitchen-coords* :copy-worldcoords))
    )
   ((equal spot "stove")
    (set-tool-on-table :object-name "gray bowl" :arm :rarm :action-mode :place :spot-name spot :use-cds-offset nil)
    (set-object *gray-bowl* (send *gray-bowl-stove-coords* :copy-worldcoords))
    )
   ))

(defun pick-up-gray-bowl (&key (spot "kitchen"))
  (cond
   ((equal spot "kitchen")
    (set-tool-on-table :object-name "gray bowl" :arm :rarm :action-mode :pick-up :spot-name "kitchen" :use-cds-offset nil)
    (assoc-object-to-arm *gray-bowl* (calc-coords-from-rel *gray-bowl* (make-coords :pos #f(-101.233 0.0 53.999) :rpy #f(0.265 1.405 -1.282))) :arm :rarm)
    )
   ((equal spot "stove")
    (set-tool-on-table :object-name "gray bowl" :arm :rarm :action-mode :pick-up :spot-name "stove" :use-cds-offset nil)
    (assoc-object-to-arm *gray-bowl* (calc-coords-from-rel *gray-bowl* (make-coords :pos #f(-89.819 12.851 40.629) :rpy #f(0.478 1.218 -0.929))) :arm :rarm)
    )
   ))


(defun receive-and-set-green-bowl (&key (arm :larm))
  (set-tool-on-table :object-name "green bowl" :arm arm :action-mode :set :spot-name "stove" :use-cds-offset nil)
  (set-object *green-bowl* (send *gray-bowl-stove-coords* :copy-worldcoords))
  )

(defun place-green-bowl (&key (arm :larm))
  (set-tool-on-table :object-name "green bowl" :arm arm :action-mode :place :spot-name "stove" :use-cds-offset nil)
  (set-object *green-bowl* (send *gray-bowl-stove-coords* :copy-worldcoords))
  )

(defun pick-up-green-bowl (&key (arm :larm))
  (set-tool-on-table :object-name "green bowl" :arm arm :action-mode :pick-up :spot-name "stove" :use-cds-offset nil)

  (assoc-object-to-arm *green-bowl* (calc-coords-from-rel *green-bowl* (make-coords :pos #f(-57.768 20.693 22.929) :rpy #f(0.115 1.25 -1.37))) :arm arm)
  )

(defun receive-and-set-oil-dispenser ()
  (set-tool-on-table :object-name "oil dispenser" :arm :larm :action-mode :set :spot-name "stove" :use-cds-offset nil)
  (set-object *oil-dispenser* (send *oil-dispenser-stove-coords* :copy-worldcoords))
  )

(defun place-oil-dispenser ()
  (set-tool-on-table :object-name "oil dispenser" :arm :larm :action-mode :place :spot-name "stove" :use-cds-offset nil)
  (set-object *oil-dispenser* (send *oil-dispenser-stove-coords* :copy-worldcoords))
  )

(defun pick-up-oil-dispenser ()
  (set-tool-on-table :object-name "oil dispenser" :arm :larm :action-mode :pick-up :spot-name "stove" :use-cds-offset nil)

  ;; (assoc-object-to-arm *oil-dispenser* (send *oil-dispenser* :handle-handle1) :arm :larm)
  (assoc-object-to-arm *oil-dispenser* (calc-coords-from-rel *oil-dispenser* (make-coords :pos #f(-9.925 5.389 113.022) :rpy #f(-0.023 0.057 3.124))) :arm :larm)
  )

(defun set-pot-on-stove (&key (arm :larm) (object-name "pot"))
  (hold-pot-on-stove :arm arm :object-name object-name)

  (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" object-name))
  (ok-wait)

  (release-pot-on-stove :arm arm)
  )


(defun pick-up-frying-pan ()
  (set-tool-on-table :object-name "frying pan" :arm :larm :action-mode :pick-up :spot-name "stove" :use-cds-offset nil)

  (assoc-object-to-arm *pan* (calc-coords-from-rel *pan* (make-coords :pos #f(-184.952 13.937 20.367) :rpy #f(-0.361 1.264 2.752))) :arm :larm)
  )

(defun place-frying-pan ()
  (set-tool-on-table :object-name "frying pan" :arm :larm :action-mode :place :spot-name "stove" :use-cds-offset nil)
  (set-object *pan* (send *pan-coords* :copy-worldcoords))
  )

(defun receive-and-set-frying-pan ()
  (set-tool-on-table :object-name "frying pan" :arm :larm :action-mode :set :spot-name "stove" :use-cds-offset nil)
  (set-object *pan* (send *pan-coords* :copy-worldcoords))
  )

;; TODO add spatula



;; TODO Add grasp without rec
(defun now-set-knife (&key (up-arm t))
  (when up-arm
    (pr2-arm-up :num 100 :arm :rarm)
    )
  (receive-and-set-knife)
  )

(defun now-set-peeler (&key (up-arm t))
  (when up-arm
    (pr2-arm-up :num 100 :arm :rarm)
    )
  (receive-and-set-peeler)
  )

(defun now-set-potato-peeler (&key (up-arm t))
  (when up-arm
    (pr2-arm-up :num 100 :arm :rarm)
    )
  (receive-and-set-potato-peeler)
  )

