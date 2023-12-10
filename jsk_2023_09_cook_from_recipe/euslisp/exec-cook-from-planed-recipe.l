#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/cooking-exec-pddl-utils.l")

;; global variables


(setq *yes-flag* nil)
(setq *speak-jp* t)


;;
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


(defun state-cb (msg)
  (print msg)
  (setq *hoge* msg)
  (setq data (send msg :data))
  (if (equal data *yes-query*)
      (progn
        (setq *yes-flag* t)
        (if *speak-jp* (send *ri* :speak-jp "状態変化を認識しました")
          (send *ri* :speak-en "I recognized the state change."))
        ))
  )

(defun ok-voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *voice-data* (send *msg* :transcript))
    (setq *voice-data-flag* t)
    (format t "voice-data: ~A ~%" *voice-data*)
    (if (equal *voice-data* '("OK"))
        (progn
          (if *speak-jp* (send *ri* :speak-jp "ありがとうございます")
            (send *ri* :speak-en "Thank you!"))
          (format t "了解しました！ ~%" *voice-data*)
          (setq *yes-flag* t)
          ))
    )
  )

(defun set-before-pour ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (cook-pick-short-replay-test)
  )

(defun pour-egg-to-pan (&key (already_set nil) (set-after t))
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (if already_set
      (cook-pour-short-replay-test)
    (cook-pick-and-pour-short-replay-test)
    )
  (if set-after
      (progn
        (clip-set-to-sunny)
        (lc_state_recognition-start-sunny)
        ))
  (reset-manip-pose :time 2000)
  )

(defun pour-egg-to-pot ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pot_data_20221027_02.l")
  (cook-pick-and-pour-short-replay-test)
  (reset-manip-pose)
  )

(defun pour-butter-to-pan ()
  ;; (load-cook-pour-file :file_name "av-files/cook_pour_butter_bowl_to_pan_data_20230603_01.l")
  (load-cook-pour-file :file_name "av-files/cook_pour_butter_bowl_to_pan_data_20230603_02.l")
  (cook-pick-and-pour-short-replay-test)
  (reset-manip-pose :time 2000)
  )

(defun stop-ih ()
  ;; (load-cook-file :file_name "av-files/cook_data_stop-ih_20221027_02.l")
  (load-cook-file :file_name "av-files/cook_data_stop-ih_20230405_01.l")
  (send *ri* :start-grasp :rarm :wait t)
  (cook-replay-once)
  (reset-manip-pose)
  )

(defun set-demo ()
  (clip-set-to-butter)
  (set-before-pour)
  )

(defun pour (ing tool)
  (format t "pour ~A to ~A ~%" ing tool)
  (cond
   ((and (equal ing "egg") (equal tool "frying pan"))
    (pour-egg-to-pan :set-after nil)
    )
   ((and (equal ing "egg") (equal tool "pot"))
    (pour-egg-to-pot)
    )
   ((and (equal ing "butter") (equal tool "frying pan"))
    (pour-butter-to-pan)
    )
   (t
    (print "Sorry. this ing and tool pattern is not defined"))
   )
  )

(defun move-until-touch (&rest args &key (arm :rarm))
  (let (av avs tms)
    (dotimes (i 15)
      (send *pr2* arm :move-end-pos #f(10 0 0) :world)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 400)))
      )
    (send *ri* :angle-vector-sequence avs tms))

  (cancel-motion-when-touch :arm arm :direction :x :threshold -15)
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

(defun fire-on (tool)
  (format t "on ~A  ~%" tool)
  (load-cook-file :file_name "av-files/cook_data_stop-ih_20230405_01.l")
  (send *ri* :start-grasp :rarm :wait t)
  (cook-replay-once)

  ;; grasp knob
  (send *ri* :move-gripper :rarm 0.08)

  (let ((ik-target (make-coords :pos (float-vector 540 -50 700) :rpy (float-vector -0.008 -0.028 3.108))))
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :rarm :inverse-kinematics
          (send ik-target :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    ;; (move-until-touch)
    ;; (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    ;; (send ik-target :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    ;; (send ik-target :translate #f(-10 0 0) :world)
    ;; (send *pr2* :rarm :inverse-kinematics
    ;;       (send ik-target :copy-worldcoords)
    ;;       :rotation-axis t
    ;;       :debug-view nil)
    ;; (send *ri* :angle-vector (send *pr2* :angle-vector))
    ;; (send *ri* :wait-interpolation)
    )

  (send *ri* :start-grasp :rarm :wait t :gain 100)
  ;; rotate
  (rotate-knob :deg 30 :arm :rarm)
  ;; release
  (send *ri* :stop-grasp :rarm :wait t)
  (set-initial-av)
  (reset-manip-pose)
  )

(defun fire-off (tool)
  (format t "off ~A ~%" tool)
  (stop-ih)
  )

(defun START-CONDITION (condition action)
  (format t "start ~A action if ~A condition ~%" action condition)

  (cond
   ((equal condition "melted liquid butter")
    (setq *yes-query* *yes-query-butter*)
    (setq *no-query* *no-query-butter*)
    (setq *raw-thre* *raw-thre-butter*)
    (setq *sma-thre* *sma-thre-butter*)
    )
   ((equal condition "cooked egg")
    (setq *yes-query* *yes-query-sunny*)
    (setq *no-query* *no-query-sunny*)
    (setq *raw-thre* *raw-thre-sunny*)
    (setq *sma-thre* *sma-thre-sunny*)
    )
   )
  ;; set
  (clip-query-change :yes-query *yes-query* :no-query *no-query*)
  (lc_state_recognition-command :yes-query *yes-query* :no-query *no-query* :raw-threshold *raw-thre* :sma-threshold *sma-thre*)

  ;; subscribeして条件を満たしていたら，actionを実行する．
  (ros::subscribe "/inference_probability_sma/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃらとかのほうが良い？マクロの問題？
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (eval action)

  (ros::unsubscribe "/inference_probability_sma/state")
  (ros::unsubscribe "/speech_to_text")
  )

;; defun action codes
(defun hold (object arm spot)
  (format t "(hold ~A ~A ~A) ~%" object arm spot)
  ;; (hold milk arm2 kitchen) (hold whisk arm1 kitchen) (hold bowl arm2 kitchen) (hold measuring-cup arm2 kitchen)
  ;; (hold small-bowl arm2 stove) (hold spatula arm2 stove) (hold salad-oil arm2 stove) (hold bowl arm2 stove) (hold spoon arm2 stove) (hold bowl arm2 stove)

  )

(defun place (object arm spot)
  (format t "(place ~A ~A ~A) ~%" object arm spot)
  ;; (place milk arm2 kitchen) (place whisk arm1 kitchen)
  ;; (place small-bowl arm2 stove) (place bowl arm2 stove) (place spatula arm2 stove) (place salad-oil arm2 stove) (place measuring-cup arm2 stove) (place spoon arm2 stove)

  )

(defun move-to (from to)
  (format t "(move-to ~A ~A) ~%" from to)
  ;; (move-to stove kitchen) (move-to kitchen stove) (move-to kitchen sink) (move-to sink stove)
  (let ((move-suc-flag nil))
    (setq move-suc-flag (move-to-spot to))
    (format t "move-to result ~A" move-suc-flag)
    (print (send *ri* :state :worldcoords))
    ))

(defun open-tap (arm)
  (format t "(open-tap ~A) ~%" arm)
  ;; (open-tap arm1)
  )

(defun close-tap (arm)
  (format t "(close-tap ~A) ~%" arm)
  ;; (close-tap arm1)
  )

(defun turn-on-stove (arm)
  (format t "(turn-on-stove ~A) ~%" arm)
  ;; (turn-on-stove arm1)
  )

(defun set-stove (before after arm)
  (format t "(set-stove ~A ~A ~A) ~%" before after arm)
  ;; (set-stove middle low-heat arm1)
  )

(defun turn-off-stove (before arm)
  (format t "(turn-off-stove ~A ~A) ~%" before arm)
  ;; (turn-off-stove middle arm1) (turn-off-stove low-heat arm1)

  ;; stop-ih rarm
  )

(defun wash (object arm)
  (format t "(wash ~A ~A) ~%" object arm)
  )

(defun pour (object vessel arm spot)
  (format t "(pour ~A ~A ~A ~A) ~%" object vessel arm spot)
  ;; (pour milk bowl arm2 kitchen) (pour salad-oil frying-pan arm2 stove) 
  )

(defun transfer (content from to arm spot)
  (format t "(transfer ~A ~A ~A ~A ~A) ~%" content from to arm spot)
  ;; (transfer butter small-bowl frying-pan arm2 stove)
  ;; (transfer egg-mixture bowl frying-pan arm2 stove) (transfer egg bowl frying-pan arm2 stove)
  ;; (transfer egg bowl pot arm2 stove)
  ;; (transfer water measuring-cup pot arm2 stove)

  )

(defun heat (object vessel state)
  (format t "(heat ~A ~A ~A) ~%" object vessel state)
  ;; (heat butter frying-pan melted-butter) (heat salad-oil frying-pan thirty-seconds) (heat water pot boiling)

  ;; look frying-pan or pot

  ;; watch cook state recognition
  )

(defun cook (object state)
  (format t "(cook ~A ~A) ~%" object state)
  ;; (cook egg-mixture half-cooked-egg) (cook egg heat-through)

  ;; look frying-pan

  )

(defun boil (object state)
  (format t "(boil ~A ~A) ~%" object state)
  ;; (boil egg three-minutes)
  )

(defun stir (object tool vessel state spot arm)
  (format t "(stir ~A ~A ~A ~A ~A ~A) ~%" object tool vessel state spot arm)
  ;; (stir water spoon pot whirlpool stove arm2)
  )

(defun mix (mixture ing-one ing-two vessel tool spot arm1 arm2)
  (format t "(mix ~A ~A ~A ~A ~A ~A ~A ~A) ~%" mixture ing-one ing-two vessel tool spot arm1 arm2)
  ;; (mix egg-mixture egg milk bowl whisk kitchen arm1 arm2)
  )

(defun stir-fry (input vessel tool state spot arm1 arm2)
  (format t "(stir-fry ~A ~A ~A ~A ~A ~A ~A) ~%" input vessel tool state spot arm1 arm2)
  ;; (stir-fry egg-mixture frying-pan spatula soft-scrambled-egg stove arm2 arm1) 
  )

(defun fetch-water (arm)
  (format t "(fetch-water ~A) ~%" arm)
  ;; (fetch-water arm2)

  ;; rarm

  )

;; exec
(defun exec-cook-from-recipe (file-name)
  (load-planed-file file-name)
  (exec-plan-list)
  )

(format t "please run (exec-cook-from-recipe file-name) ~%")
