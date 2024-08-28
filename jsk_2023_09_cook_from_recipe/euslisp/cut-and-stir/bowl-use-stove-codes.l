#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/tool-use-in-kitchen-codes.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/73b2-kitchen-coords.l")

;; set global variable
(setq *debug-flag* t)
(setq *s-time* 3)

(setq *x-thre* -10)
(setq *cb-flag* nil)

(unless (boundp '*pot*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pot-73b2.l")
    (setq *pot* (cooking-pot))
    ))

(unless (boundp '*pan*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pan-73b2.l")
    (setq *pan* (cooking-pan))
    ))

(unless (boundp '*spatula*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/spatula.l")
    (setq *spatula* (spatula))
    ))

(unless (boundp '*ladle*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/ladle.l")
    (setq *ladle* (ladle))
    ))

(unless (boundp '*mcup*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/measuring-cup-73b2.l")
    (setq *mcup* (measuring-cup-73b2))
    ))

(unless (boundp '*bowl-1*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-1.l")
    (setq *bowl-1* (bowl-1))
    ))

(unless (boundp '*bowl-2*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-2.l")
    (setq *bowl-2* (bowl-2))
    ))

(unless (boundp '*bowl-3*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-3.l")
    (setq *bowl-3* (bowl-3))
    ))

(unless (boundp '*gray-bowl*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/gray-bowl.l")
    (setq *gray-bowl* (gray-bowl))
    ))

(unless (boundp '*green-bowl*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/green-bowl.l")
    (setq *green-bowl* (green-bowl))
    ))

(unless (boundp '*oil-dispenser*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/dispenser.l")
    (setq *oil-dispenser* (dispenser))
    ))

(unless (boundp '*stove-kitchen-plane*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/stove-kitchen-plane.l")
    (setq *stove-kitchen-plane* (stove-kitchen-plane))
    ))

(unless (boundp '*arrow*)
  (progn
    (load "models/arrow-object.l")
    (setq *arrow* (arrow))
    ))

(defun bowl-stove-init (&key (reset-obj-cds t) (init-cds t) (type :old-curry))
  ;; init
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  ;; (setq *stove-spot* (make-coords :pos (float-vector 1200 8100 30000) :rpy (float-vector pi 0 0))) ;; original

  ;; set global coords
  (when init-cds
    (73b2-stove-coords-init :type type))

  ;; set objects
  (send *stove-kitchen-plane* :newcoords  (send *stove-kitchen-plane-coords* :copy-worldcoords))
  (when reset-obj-cds
    (case type
          (:sunny-side-up
           (dissoc-object *pan*)
           (send *pan* :newcoords (send *pan-coords* :copy-worldcoords))

           (dissoc-object *oil-dispenser*)
           (send *oil-dispenser* :newcoords (send *oil-dispenser-stove-coords* :copy-worldcoords))

           (dissoc-object *gray-bowl*)
           (send *gray-bowl* :newcoords (send *gray-bowl-stove-coords* :copy-worldcoords))

           (objects (list *pr2* *stove-kitchen-plane* *pan* *gray-bowl* *oil-dispenser*))
           )
          (:butter-sunny-side-up
           (dissoc-object *pan*)
           (send *pan* :newcoords (send *pan-coords* :copy-worldcoords))

           (dissoc-object *gray-bowl*)
           (send *gray-bowl* :newcoords (send *gray-bowl-stove-coords* :copy-worldcoords))

           (dissoc-object *green-bowl*)
           (send *green-bowl* :newcoords (send *green-bowl-stove-coords* :copy-worldcoords))

           (objects (list *pr2* *stove-kitchen-plane* *pan* *gray-bowl* *green-bowl*))
           )
          (:scrambled-egg
           (dissoc-object *pan*)
           (send *pan* :newcoords (send *pan-coords* :copy-worldcoords))

           (dissoc-object *green-bowl*)
           (send *green-bowl* :newcoords (send *green-bowl-stove-coords* :copy-worldcoords))

           (dissoc-object *spatula*)
           (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords))

           (objects (list *pr2* *stove-kitchen-plane* *pan* *green-bowl* *spatula*))
           )
          (:poached-egg
           (dissoc-object *pot*)
           (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))

           (dissoc-object *gray-bowl*)
           (send *gray-bowl* :newcoords (send *gray-bowl-stove-coords* :copy-worldcoords))

           ;; spoon

           (objects (list *pr2* *stove-kitchen-plane* *pot* *gray-bowl*))
           )
          (:curry
           (dissoc-object *spatula*)
           (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords)) ;; spatula on the cutting board

           (dissoc-object *ladle*)
           (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords))

           (dissoc-object *pot*)
           (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))

           (dissoc-object *mcup*)
           (send *mcup* :newcoords (send *mcup-coords* :copy-worldcoords))

           (dissoc-object *bowl-2*)
           (send *bowl-2* :newcoords (send *bowl-2-stove-coords* :copy-worldcoords))

           (dissoc-object *gray-bowl*)
           (send *gray-bowl* :newcoords (send *gray-bowl-stove-coords* :copy-worldcoords))

           (dissoc-object *green-bowl*)
           (send *green-bowl* :newcoords (send *green-bowl-stove-coords* :copy-worldcoords))

           (dissoc-object *oil-dispenser*)
           (send *oil-dispenser* :newcoords (send *oil-dispenser-stove-coords* :copy-worldcoords))

           ;; (objects (list *pr2* *scene* *spatula* *mcup* *ladle* *pot* *bowl-1* *bowl-2* *bowl-3* *oil-dispenser*))
           ;; (move-to-stove-irt)
           ;; (update-view)
           (objects (list *pr2* *stove-kitchen-plane* *spatula* *mcup* *ladle* *pot* *bowl-2* *gray-bowl* *green-bowl* *oil-dispenser*))
           )
          (:old-curry
           (dissoc-object *spatula*)
           (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords)) ;; spatula on the cutting board

           (dissoc-object *ladle*)
           (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords))

           (dissoc-object *pot*)
           (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))

           (dissoc-object *mcup*)
           (send *mcup* :newcoords (send *mcup-coords* :copy-worldcoords))

           (dissoc-object *bowl-1*)
           (send *bowl-1* :newcoords (send *bowl-1-stove-coords* :copy-worldcoords))

           (dissoc-object *bowl-2*)
           (send *bowl-2* :newcoords (send *bowl-2-stove-coords* :copy-worldcoords))

           (dissoc-object *bowl-3*)
           (send *bowl-3* :newcoords (send *bowl-3-stove-coords* :copy-worldcoords))

           (dissoc-object *oil-dispenser*)
           (send *oil-dispenser* :newcoords (send *oil-dispenser-stove-coords* :copy-worldcoords))

           ;; (objects (list *pr2* *scene* *spatula* *mcup* *ladle* *pot* *bowl-1* *bowl-2* *bowl-3* *oil-dispenser*))
           ;; (move-to-stove-irt)
           ;; (update-view)
           (objects (list *pr2* *stove-kitchen-plane* *spatula* *mcup* *ladle* *pot* *bowl-1* *bowl-2* *bowl-3* *oil-dispenser*))
           ))

    )

  ;; def bowl grasp coords
  (setq *bowl-1-grasp-coords* (make-coords :pos (float-vector 383 8425 30889) :rpy (float-vector 2.892 1.01 1.404)))
  (setq *bowl-2-grasp-coords* (make-coords :pos (float-vector 344 8616 30880) :rpy (float-vector 3.016 0.995 1.718)))
  (setq *bowl-2-grasp-set-coords* (make-coords :pos (float-vector 558.94 8455.526 30890.992) :rpy (float-vector -2.649 1.102 1.301)))
  (setq *bowl-2-grasp-set-larm-coords* (make-coords :pos (float-vector 550.455 8389.4 30870.472) :rpy (float-vector 3.006 0.965 1.642)))

  (setq *bowl-3-grasp-coords* (make-coords :pos (float-vector 672 7632 30873) :rpy (float-vector -2.152 1.02 1.606)))
  (setq *bowl-4-grasp-coords* (make-coords :pos (float-vector 567 7824 30920) :rpy (float-vector -2.624 1.195 2.113)))
  )

(bowl-stove-init)

;; TODO fix
;; add for rosservice
;; (ros::load-ros-manifest "std_srvs")
;; (ros::wait-for-service "after_stow_data_collection/save_request")
;; (setq req (instance std_srvs::TriggerRequest :init))

;; (defun rossrv-test ()
;;   (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
;;   )

;; ;; add for voice recognition
;; (ros::load-ros-manifest "speech_recognition_msgs")
;; (setq *data-flag* nil)
;; (defun voice-cb (msg)
;;   (when msg
;;     (setq *msg* msg)
;;     (setq *data* (send *msg* :transcript))
;;     (setq *data-flag* t)
;;     (format t "data: ~A ~%" *data*)
;;     )
;;   )

;; (defun dialogue-func ()
;;   (ros::unsubscribe "/speech_to_text")
;;   (setq *data-flag* nil)
;;   (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-cb)
;;   (until *data-flag*
;;          (ros::spin-once)
;;          (ros::sleep)
;;          )
;;   (send *ri* :speak-jp "ありがとうございます")
;;   (unix:sleep 1)
;;   )

;; (setq *ok-flag* nil)
;; (defun voice-ok-cb (msg)
;;   (when msg
;;     (setq *msg* msg)
;;     (setq *data* (send *msg* :transcript))
;;     (if (equal *data* '("OK"))
;;         (progn
;;           (format t "了解しました！ ~%" *data*)
;;           (setq *ok-flag* t)
;;           )
;;       (format t "data: ~A ~%" *data*)
;;       )
;;     )
;;   )

;; (defun ok-grasp-larm ()
;;   (ros::unsubscribe "/speech_to_text")
;;   (setq *ok-flag* nil)
;;   (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
;;   (until *ok-flag*
;;          (ros::spin-once)
;;          (ros::sleep)
;;          )
;;   (send *ri* :speak-jp "ありがとうございます")
;;   (unix:sleep *w-time*)
;;   (send *ri* :start-grasp :larm :wait t)
;;   )

;; (defun receive-with-dialogue-larm ()
;;   ;; (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい") ;; 喋らせている想定でスタート
;;   (setq *yes-flag* nil)
;;   (until *yes-flag*
;;          (send *ri* :stop-grasp :larm :wait t)
;;          (ok-grasp-larm)
;;          (send *ri* :speak-jp "上手く掴めていますか？")
;;          (dialogue-func)
;;          (if (equal *data* '("はい"))
;;              (setq *yes-flag* t)
;;            (progn
;;              (send *ri* :speak-jp "グリッパを開きます.もう一度お願いします")
;;              (unix:sleep *w-time*)
;;              )
;;            )
;;          )

;;   (send *ri* :speak-jp "次の行動に移ります")
;;   (unix:sleep *w-time*)
;;   )

;; ;; add for grasp detection
;; (defun grasp-fail-detection-larm (&rest args &key (g-thre 10) &allow-other-keys)
;;   (setq *fail-flag* nil)
;;   (setq gripper-len (send *ri* :state :gripper :larm :position))
;;   (if (< gripper-len g-thre)
;;       (setq *fail-flag* t))
;;   )

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (now-set-bowls) or (set-bowl-1) ~%")

;; def util-funcs
;; update funcs
(defun set-bowl-on-table (&key (object-name "gray bowl") (arm :rarm) (action-mode :set) (spot-name "stove") (use-cds-offset nil))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        adj-target-cds
        )
    (cond
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
      (setq pre-set-val #f(-100 50 0)) ;; for upper #f(0 0 150) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *green-bowl-stove-coords* (make-coords :pos #f(-57.768 20.693 22.929) :rpy #f(0.115 1.25 -1.37))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *green-bowl-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "green bowl") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(48.7972 1.40098 47.7424 -89.0343 68.0991 -99.506 -53.0755))) ;; TODO
      (setq pre-set-val #f(-100 50 0)) ;; for upper #f(0 0 150) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *green-bowl-stove-coords* (make-coords :pos #f(-57.768 20.693 22.929) :rpy #f(0.115 1.25 -1.37))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *green-bowl-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     ((and (string= object-name "oil dispenser") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(48.7972 1.40098 47.7424 -89.0343 68.0991 -99.506 -53.0755))) ;; TODO
      (setq pre-set-val #f(-100 50 0)) ;; for upper #f(0 0 150) :world

      ;; calc from defined coords
      (send *arrow* :newcoords (calc-coords-from-rel *oil-dispenser-stove-coords* (make-coords :pos #f(-9.925 5.389 113.022) :rpy #f(-0.023 0.057 3.124))))
      (format t "~A coords ~A , set target coords is ~A ~%" object-name (send *oil-dispenser-stove-coords* :copy-worldcoords) (send *arrow* :copy-worldcoords))
      (send set-target-coords :newcoords (send *arrow* :copy-worldcoords))
      )
     (t
      (format t "Sorry, object-name ~A, spot-name ~A, arm ~A is not defined now !!!~%" object-name spot-name arm)
      (return-from set-bowl-on-table nil)
      )
     )

    (if use-cds-offset
        (setq adj-target-cds (adjust-cds-with-spot set-target-coords spot-name))
      (setq adj-target-cds (send set-target-coords :copy-worldcoords))
      )
    (grasp-object-primitive :pre-set-avs pre-set-avs :grasp-coords adj-target-cds :pre-set-val pre-set-val :arm arm :action-mode action-mode :object-name object-name)

    ;; TODO add dissoc object and put object
    ))

(defun receive-and-set-gray-bowl ();; TODO add head
  (set-bowl-on-table :object-name "gray bowl" :arm :rarm :action-mode :set :spot-name "stove" :use-cds-offset nil)
  )

(defun put-gray-bowl ()
  (set-bowl-on-table :object-name "gray bowl" :arm :rarm :action-mode :put :spot-name "stove" :use-cds-offset nil)
  )

(defun receive-and-set-green-bowl ()
  (set-bowl-on-table :object-name "green bowl" :arm :larm :action-mode :set :spot-name "stove" :use-cds-offset nil)
  )

(defun put-green-bowl ()
  (set-bowl-on-table :object-name "green bowl" :arm :larm :action-mode :put :spot-name "stove" :use-cds-offset nil)
  )

(defun receive-and-set-oil-dispenser ()
  (set-bowl-on-table :object-name "oil dispenser" :arm :larm :action-mode :set :spot-name "stove" :use-cds-offset nil)
  )

(defun put-oil-dispenser ()
  (set-bowl-on-table :object-name "oil dispenser" :arm :larm :action-mode :put :spot-name "stove" :use-cds-offset nil)
  )

;; TODO fix
(defun reset-rarm ()

  (setq *rav0* (float-vector -25.6468 7.87241 -48.2704 -85.3763 253.675 -77.8887 -147.102))
  (send *pr2* :rarm :angle-vector *rav0*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 556.424 8603.557 31158.464) :rpy (float-vector -2.286 0.656 0.542)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *rav1* (float-vector -20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav1*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8828.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *pr2* :rarm :angle-vector *rav3*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 800.191 8689.104 30866.677) :rpy (float-vector -2.341 -0.222 -0.482)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *pr2* :rarm :angle-vector *rav3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view nil
        :stop 20)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  (setq *lav1* (float-vector 16.6498 -20.1996 123.812 -51.9785 -42.6397 -65.2851 -0.059116))
  (send *pr2* :larm :angle-vector *lav1*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 509.999 8489.998 31189.999) :rpy (float-vector 1.571 0.0 1.349)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (setq *lav2* (float-vector 41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -0.0))
  (send *pr2* :larm :angle-vector *lav2*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 660.0 8390.0 31290.0) :rpy (float-vector 1.571 0.0 1.722)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *lav3* (float-vector 75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -0.0))
  (send *pr2* :larm :angle-vector *lav3*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 800.188 8310.893 30866.671) :rpy (float-vector 2.341 -0.222 0.589)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  
  
  (setq *lav4* (float-vector 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  )

(defun before-recieve-larm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;;少し前に
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8361 31167) :rpy (float-vector 1.571 1.047 1.571)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *pr2* :larm :angle-vector #f(30.046 -16.1647 77.4608 -67.7082 57.0472 -86.8259 -43.9204))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation) 
  )

(defun put-bowl-larm ()
  ;; (send *arrow* :translate (float-vector 0 0 200) :world) ;; がしてある状態で使う
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun before-recieve-rarm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;;少し前に
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8739 31167) :rpy (float-vector -1.571 1.047 1.571)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *pr2* :rarm :angle-vector #f(-37.8868 -20.239 -85.7141 -64.0592 312.721 -87.1625 -148.994))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun put-bowl-rarm ()
  ;; (send *arrow* :translate (float-vector 0 0 200) :world) ;; がしてある状態で使う
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :rarm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation) 
  )

(defun grasp-bowl-larm ()
  (before-recieve-larm)
  
  (send *ri* :stop-grasp :larm :wait t)
  
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :larm :wait t)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun grasp-bowl-rarm ()
  (before-recieve-rarm)
  
  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


;; bowl funcs
(defun recieve-bowl-1 ()
  (before-recieve-rarm)

  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "ボウル１を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)

  (warn "please run (put-bowl-1) ~%")
  )

(defun put-bowl-1 ()
  ;; ボウル１を置く位置
  (send *arrow* :newcoords (send *bowl-1-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)
  )

(defun recieve-bowl-2 ()
  (before-recieve-larm)

  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ボウル２を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-2-model) ~%")
  )

(defun recieve-bowl-2-with-dialogue ()
  (before-recieve-larm)

  (send *ri* :speak-jp "ボウル２を渡す準備をして，合図をして下さい")
  (receive-with-dialogue-larm)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-2-model) ~%")
  )

(defun put-bowl-2 ()
  ;; ボウル２を置く位置
  (send *arrow* :newcoords (send *bowl-2-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-rarm)
  )


(defun recieve-bowl-3 ()
  (before-recieve-larm)

  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ボウル３を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-3) ~%")
  )

(defun recieve-bowl-3-with-dialogue ()
  (before-recieve-larm)

  (send *ri* :speak-jp "ボウル３を渡す準備をして，合図をして下さい")
  (receive-with-dialogue-larm)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-3) ~%")
  )

(defun recieve-bowl-4 ()
  (before-recieve-larm)

  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ボウル４を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-4) ~%")
  )


(defun put-bowl-3 ()
  ;; (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  ;; (send *pr2* :larm :angle-vector *larm1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.916 8025.169 31085.839) :rpy (float-vector 2.561 1.128 2.104)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; ボウル３を置く位置
  (send *arrow* :newcoords (send *bowl-3-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)
  )

(defun put-bowl-4 ()
  ;; (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  ;; (send *pr2* :larm :angle-vector *larm1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.916 8025.169 31085.839) :rpy (float-vector 2.561 1.128 2.104)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; ボウル４を置く位置
  (send *arrow* :newcoords (send *bowl-4-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)
  )

(defun grasp-bowl-3 ()
  ;; ボウル１の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-3-grasp-coords* :copy-worldcoords))

  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")
  )

(defun grasp-bowl-4 ()
  ;; ボウル１の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-4-grasp-coords* :copy-worldcoords))

  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")
  )


(defun grasp-bowl-2 ()
  ;; ボウル２の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-2-grasp-coords* :copy-worldcoords))

  (grasp-bowl-rarm)

  (warn "please run (move-bowl-2-set) ~%")
  )

(defun move-bowl-2-set ()
  (send *pr2* :rarm :move-end-pos (float-vector 100 0 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; ボウル２を置く位置 set
  (send *arrow* :newcoords (send *bowl-2-grasp-set-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-rarm)
  )


(defun grasp-bowl-2-set ()
  ;; ボウル２の位置 set
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-2-grasp-set-larm-coords* :copy-worldcoords))
  
  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")  
  )

(defun put-bowl-2-set ()
  ;; ボウル２の位置 set
  (send *arrow* :newcoords (send *bowl-2-grasp-set-larm-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-bowl-1 ()
  ;; ボウル１の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-1-grasp-coords* :copy-worldcoords))
  
  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")  
  )

(defun grasp-bowl-2-set-rarm ()
  ;; ボウル２の位置 set
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-2-grasp-set-coords* :copy-worldcoords))
  
  (grasp-bowl-rarm)
  
  (warn "please run (put-bowl-2) ~%")  
  )

;; transfer funcs
(defun transfer-to-pot ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.911 8325.179 31085.843) :rpy (float-vector 2.561 1.128 2.104))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  ;; (send *pr2* :larm :angle-vector *larm1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.916 8025.169 31085.839) :rpy (float-vector 2.561 1.128 2.104)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  ;; (send *pr2* :larm :angle-vector *larm2*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 536.332 7996.084 31098.396) :rpy (float-vector  -1.915 0.881 -2.415)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 463.549 8018.53 31099.284) :rpy (float-vector -1.743 0.802 -1.842)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 465 8005 31130) :rpy (float-vector -1.571 0.436 -1.571)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")  
  )

(defun after-transfer ()
  ;; (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  ;; (send *pr2* :larm :angle-vector *larm2*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 536.332 7996.084 31098.396) :rpy (float-vector -1.915 0.881 -2.415)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  ;; (send *pr2* :larm :angle-vector *larm1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.916 8025.169 31085.839) :rpy (float-vector 2.561 1.128 2.104)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-bowl-1) or (put-bowl-2-set) ~%")  
  )


(defun transfer-to-pot-left ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 609.875 7802.164 31145.744) :rpy (float-vector 2.719 0.798 1.816)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector -100 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  (send *pr2* :larm :angle-vector *larm2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 463.549 8018.53 31099.284) :rpy (float-vector -1.743 0.802 -1.842)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 465 8005 31130) :rpy (float-vector -1.571 0.436 -1.571)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer-left) ~%")
  )

(defun after-transfer-left ()
  ;; (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  ;; (send *pr2* :larm :angle-vector *larm2*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 536.332 7996.084 31098.396) :rpy (float-vector -1.915 0.881 -2.415)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  ;; (send *pr2* :larm :angle-vector *larm1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.916 8025.169 31085.839) :rpy (float-vector 2.561 1.128 2.104)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 100 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-bowl-3) or (put-bowl-4) ~%")  
  )


;; spatula funcs
(defun squeeze-test-set ()
  (send *ri* :start-grasp :rarm :gain 30 :wait t)
  
  ;; (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  ;; (send *pr2* :rarm :angle-vector *rav0*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8828.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8550 31145) :rpy (float-vector -3.048 -0.062 -1.634)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 550 8400 31150) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 600 8300 31200) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 500 8200 31080) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(0 70 -60) :world)
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (squeeze-test) ~%")
  )

(defun squeeze-test ()
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate (float-vector 0 50 -50) :world)
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *arrow* :translate (float-vector 0 -10 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
          :rotation-axis t
          :debug-view nil)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (elt (send *spatula* :attention) 1) :copy-worldcoords))
  
  (setq avs (list))
  (setq tms (list))

  ;; tmp 
  (setq height (- (elt (send (send *arrow* :copy-worldcoords) :worldpos) 2) 30960))
  
  (send *arrow* :translate (float-vector 0 0 (* height -0.5)) :world)
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
        :rotation-axis t
        :debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *arrow* :translate (float-vector 0 40 (* height -0.3)) :world)
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
        :rotation-axis t
        :debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *arrow* :translate (float-vector 0 40 (* height -0.3)) :world)
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
        :rotation-axis t
        :debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (elt (send *spatula* :attention) 1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 30 30) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *spatula* :attention) 1)
        :rotation-axis t
        :debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(0 60 -50) :world)
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun avoid-rarm ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 471 8105 31070) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 550 8450 31150) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 550 8300 31250) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8600 31145) :rpy (float-vector -3.048 -0.062 -1.634)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)

  ;; (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  ;; (send *pr2* :rarm :angle-vector *rav0*)
  (send *arrow* :newcoords (make-coords :pos (float-vector  628.029 8828.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")
  )


;; mcup codes tmp
(defun set-mcup ()
  (if (not (eql (send *mcup* :parent) nil))
      (send (send *mcup* :parent) :dissoc *mcup*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *mcup* :handle-handle1) :copy-worldcoords))
    (send local-cds :assoc *mcup*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *mcup*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *mcup*)
  )

(defun grasp-mcup ()
  ;; mcupの位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *mcup* :handle-handle1) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-mcup)
  
  (warn "please run (carry-mcup-pose) ~%")
  )

(defun put-mcup ()
  ;; mcupを置く位置
  (if (not (eql (send *mcup* :parent) nil))
      (send (send *mcup* :parent) :dissoc *mcup*))
  (send *mcup* :newcoords (send *mcup-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *mcup* :handle-handle1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun carry-mcup-pose ()
  (setq *lav-cm* #f(38.442 -20.2481 94.8038 -104.353 117.885 -64.3683 -258.356))
  (send *pr2* :larm :angle-vector *lav-cm*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 604.833 8300.101 31079.393) :rpy (float-vector 3.141 0.75 0.0)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)
  )

(defun transfer-mcup ()
  (set-mcup)
  
  ;; スライドさせて行く
  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos #f(100 0 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 移し始める座標
  (send *arrow* :newcoords (make-coords :pos (float-vector 510 8100 31080) :rpy (float-vector 3.14 0 0)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *mcup* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  ;; 傾けていく
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 5)
    (send *arrow* :rotate (deg2rad 10) :y)
    (send *pr2* :larm :inverse-kinematics
          *arrow*
          :move-target (car (send *mcup* :attention))
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  ;; 移し終わったかどうか等を判定する？
  
  (warn "please run (after-mcup) ~%")
  )

(defun after-mcup ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 510 8100 31080) :rpy (float-vector 3.14 0 0)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *mcup* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 100 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  x
  (carry-mcup-pose)
  
  (warn "please run (put-mcup) ~%")
  )

(defun recieve-mcup ()
  (carry-mcup-pose)
  
  ;; mcupを受け取る
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "軽量カップを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)
  
  (set-mcup)
  
  (warn "please run (put-mcup) ~%")
  )

(defun recieve-mcup-with-dialogue ()
  (carry-mcup-pose)
  
  ;; mcupを受け取る
  (send *ri* :speak-jp "計量カップを渡す準備をして，合図をして下さい")
  (receive-with-dialogue-larm)  
  (send *ri* :start-grasp :larm :wait t)
  
  (set-mcup)
  (warn "please run (put-mcup) ~%")
  )


;; oil-dispenser codes
(defun set-oil-dispenser ()
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
    (send local-cds :assoc *oil-dispenser*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *oil-dispenser*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *oil-dispenser*)
  )

(defun recieve-oil-dispenser ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8361 31167) :rpy (float-vector 3.14 0 0)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *pr2* :larm :angle-vector #f(25.9612 -20.2538 51.0301 -90.7875 148.483 -82.2836 126.197))  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; oil-dispenserを置く位置
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *oil-dispenser* :newcoords (send *oil-dispenser-stove-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ディスペンサーを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (set-oil-dispenser) 
  )

(defun recieve-oil-dispenser-with-dialogue ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8361 31167) :rpy (float-vector 3.14 0 0)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *pr2* :larm :angle-vector #f(25.9612 -20.2538 51.0301 -90.7875 148.483 -82.2836 126.197))  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; oil-dispenserを置く位置
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *oil-dispenser* :newcoords (send *oil-dispenser-stove-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :speak-jp "ディスペンサーを渡す準備をして，合図をして下さい")
  (receive-with-dialogue-larm)  
  (send *ri* :start-grasp :larm :wait t)

  (set-oil-dispenser) 
  )

(defun put-oil-dispenser ()
  ;; oil-dispenserを置く位置
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *oil-dispenser* :newcoords (send *oil-dispenser-stove-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-oil-dispenser ()
  ;; oil-dispenserの位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-oil-dispenser)
  
  (warn "please run (add-oil-set) ~%")
  )

(defun grasp-oil-dispenser-with-fail-detection ()
  (setq tmp-coords (send *oil-dispenser* :copy-worldcoords))
  (grasp-oil-dispenser)
  
  ;; 失敗を検知する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (if (not (eql (send *oil-dispenser* :parent) nil))
            (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
        (send *oil-dispenser* :newcoords (send tmp-coords :copy-worldcoords))
        (grasp-oil-dispenser)
        (grasp-fail-detection-larm :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (send *ri* :speak-jp "ディスペンサーの把持が失敗しました，渡す準備をして合図をして下さい")
              (receive-with-dialogue-larm)  
              (send *ri* :start-grasp :larm :wait t)
              ))
        ))
  
  (warn "please run (add-oil-set) ~%")
  )

(defun add-oil-set ()
  ;; dispenserを位置に
  (send *pr2* :larm :move-end-pos #f(100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 120) :world)
  (send *arrow* :rotate (deg2rad -90) :x)
  (send *arrow* :rotate (deg2rad -90) :y :world)
  
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *oil-dispenser* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;;右腕をセットしておく
  (before-recieve-rarm)
  
  ;; 右腕をセットする位置
  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
   
  (send *arrow* :translate #f(0 100 80) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :rarm :wait t)
 
  (send *arrow* :translate #f(0 -100 -80) :world)
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

(defun after-oil ()
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *pr2* :rarm :end-coords :assoc *oil-dispenser*)
  
  ;; 上にして持ち替える
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(150 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :x)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; IK が解ける用に腕を少し下げる
  (send *arrow* :translate #f(0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle1) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :z)
  (send *arrow* :translate #f(100 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-100 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :larm :wait t)
  
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *pr2* :larm :end-coords :assoc *oil-dispenser*)
  
  ;; 右腕を戻して左腕をputの前位置にする．
  (send *ri* :stop-grasp :rarm :wait t)
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 100 0) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (reset-rarm)

  (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)


  (warn "please run (put-oil-dispenser) ~%")
  )

;; bowl model codes
(defun set-bowl-1-model ()
  (if (not (eql (send *bowl-1* :parent) nil))
      (send (send *bowl-1* :parent) :dissoc *bowl-1*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-1*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-1*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-1*)
  )

(defun put-bowl-1-model ()
  ;; ボウル１を置く位置
  (if (not (eql (send *bowl-1* :parent) nil))
      (send (send *bowl-1* :parent) :dissoc *bowl-1*))
  (send *bowl-1* :newcoords (send *bowl-1-stove-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-bowl-1-model ()
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-bowl-1-model)
  
  (warn "please run (transfer-bowl-1-to-pot) ~%")  
  )

(defun set-bowl-2-model ()
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-2*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-2*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-2*)
  )

(defun put-bowl-2-model ()  
  ;; ボウル２を置く位置
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (send *bowl-2* :newcoords (send *bowl-2-stove-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-bowl-2-model ()
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-bowl-2-model)
  
  (warn "please run (transfer-bowl-2-to-pot) ~%")  
  )


(defun set-bowl-3-model ()
  (if (not (eql (send *bowl-3* :parent) nil))
      (send (send *bowl-3* :parent) :dissoc *bowl-3*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-3* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-3*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-3*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-3*)
  )

(defun put-bowl-3-model ()
  ;; ;; (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  ;; ;; (send *pr2* :larm :angle-vector *larm1*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 550.916 8025.169 31085.839) :rpy (float-vector 2.561 1.128 2.104)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  ;; ボウル３を置く位置
  (if (not (eql (send *bowl-3* :parent) nil))
      (send (send *bowl-3* :parent) :dissoc *bowl-3*))
  (send *bowl-3* :newcoords (send *bowl-3-stove-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-3* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)  
  )

(defun grasp-bowl-3-model ()
  ;; ボウル３の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-3* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)

  (set-bowl-3-model)
  
  (warn "please run (transfer-bowl-3-to-pot) ~%")  
  )

(defun transfer-to-pot-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.911 8325.179 31085.843) :rpy (float-vector 2.561 1.128 2.104)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

(defun transfer-to-pot-left-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 609.875 7802.164 31145.744) :rpy (float-vector 2.719 0.798 1.816))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector -100 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )


(defun transfer-bowl-1-to-pot ()
  (set-bowl-1-model)
  
  (transfer-to-pot-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)

  (look-at-cds *arrow*)

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *bowl-1* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (after-transfer) ~%")  
  )

(defun transfer-bowl-2-to-pot ()
  (set-bowl-2-model)
  
  (transfer-to-pot-left-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)

  (look-at-cds *arrow*)

  ;; (send *arrow* :translate #f(10 0 20) :world)  
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :move-target (send *bowl-2* :attention-attention0)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 431.773 7970.441 31105.956) :rpy (float-vector -2.51 0.973 -2.598)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")  
  )

(defun transfer-bowl-3-to-pot ()
  (set-bowl-3-model)
  
  (transfer-to-pot-left-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  
  (look-at-cds *arrow*)
  
  ;; (send *arrow* :translate #f(10 0 20) :world)
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :move-target (send *bowl-3* :attention-attention0)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 431.773 7970.441 31105.956) :rpy (float-vector -2.51 0.973 -2.598)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (after-transfer-left) ~%")
  )

(defun transfer-bowl-4-to-pot ()
  (set-bowl-4-model)
  
  (transfer-to-pot-left-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  
  (look-at-cds *arrow*)

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *bowl-4* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (after-transfer-left) ~%")
  )


;; ボウル２をセット
(defun now-set-2-model ()
  (recieve-bowl-2)
  (put-bowl-2-model)
  (reset-larm)
  )

(defun now-set-2-model-with-dialogue ()
  (recieve-bowl-2-with-dialogue)
  (put-bowl-2-model)
  (reset-larm)
  )

(defun now-set-3-model ()
  (recieve-bowl-3)
  (put-bowl-3-model)
  (reset-larm)
  )

(defun now-set-3-model-with-dialogue ()
  (recieve-bowl-3-with-dialogue)
  (put-bowl-3-model)
  (reset-larm)
  )

;; ボウル１〜４をセット
(defun now-set-2-3 ()
  (now-set-2-model)
  (now-set-3-model)
  )

(defun now-transfer-left ()
  (transfer-to-pot-left)
  
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer-left)
  )

(defun now-transfer-1-model ()
  (grasp-bowl-1-model)
  
  (transfer-bowl-1-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)

  (rossrv-test)
  
  (avoid-rarm)
  
  (after-transfer)
  (put-bowl-1-model)
  (reset-larm)
  )

(defun now-transfer-2-model ()
  (grasp-bowl-2-model)
  
  (transfer-bowl-2-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)

  ;; (rossrv-test)
  
  (avoid-rarm)
  
  (after-transfer-left)
  (put-bowl-2-model)
  (reset-larm)
  )

(defun now-transfer-3-model ()
  (grasp-bowl-3-model)

  (transfer-bowl-3-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)

  ;; (rossrv-test)
  
  (avoid-rarm)
  
  (after-transfer-left)
  (put-bowl-3-model)
  (reset-larm)
  )


(defun now-set-oil ()
  (recieve-oil-dispenser)
  (put-oil-dispenser)
  (reset-larm)
  )

(defun now-set-oil-with-dialogue ()
  (recieve-oil-dispenser-with-dialogue)
  (put-oil-dispenser)
  (reset-larm)
  )

(defun now-add-oil ()
  (grasp-oil-dispenser)
  (add-oil-set)
  (add-oil)
  (after-oil)
  
  (put-oil-dispenser)
  (reset-larm)
  )

(defun now-add-oil-with-fail-detection ()
  (grasp-oil-dispenser-with-fail-detection)
  (add-oil-set)
  (add-oil)
  (after-oil)
  
  (put-oil-dispenser)
  (reset-larm)
  )


(defun now-set-mcup ()
  (recieve-mcup)
  (put-mcup)
  (reset-larm)
  )

(defun now-set-mcup-with-dialogue ()
  (recieve-mcup-with-dialogue)
  (put-mcup)
  (reset-larm)
  )

(defun now-grasp-mcup ()
  ;; (set-pose)
  (grasp-mcup)
  (carry-mcup-pose)
  
  (warn "please go to sink spot ~%")
  )

(defun now-pour-water ()
  (carry-mcup-pose)
  (transfer-mcup)
  (after-mcup)
  (put-mcup)
  (reset-larm)
  )

