#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; global variables

;; defun action codes
(defun hold (object arm spot)
  (let (cmd-str)
    (setq cmd-str (format nil "(hold ~A ~A ~A)" object arm spot))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )
  ;; (hold milk arm2 kitchen) (hold whisk arm1 kitchen) (hold bowl arm2 kitchen) (hold measuring-cup arm2 kitchen)
  ;; (hold small-bowl arm2 stove) (hold spatula arm2 stove) (hold salad-oil arm2 stove) (hold bowl arm2 stove) (hold spoon arm2 stove) (hold bowl arm2 stove)

  ;; todo
  (cond
   ((or (string= object "salad-oil") (string= object "oil"))
    (place-objects-on-table :object-name "あぶら" :arm :larm :spot-name spot :grasp-flag t)
    )
   ((string= object "bowl")
    (place-objects-on-table :object-name "ボウル1" :arm :rarm :spot-name spot :grasp-flag t)
    )
   ((string= object "small-bowl")
    (place-objects-on-table :object-name "ボウル0" :arm :rarm :spot-name spot :grasp-flag t)
    )
   ((string= object "spatula")
    (place-objects-on-table :object-name "ヘラ" :arm :rarm :spot-name spot :grasp-flag t)
    )
   ((string= object "broccoli")
    (place-objects-on-table :object-name "ブロッコリー" :arm :larm :spot-name spot :grasp-flag t)
    )
   ((string= object "pot")
    (place-objects-on-table :object-name "pot" :arm :larm :spot-name spot :grasp-flag t)
    )
   (t
    (format t "object ~A, arm ~A, spot ~A is not defined !!!~%" object arm spot)
    (return-from hold nil)
    )
   )
  )

(defun place (object arm spot)
  (let (cmd-str)
    (setq cmd-str (format nil "(place ~A ~A ~A) ~%" object arm spot))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; (place milk arm2 kitchen) (place whisk arm1 kitchen)
  ;; (place small-bowl arm2 stove) (place bowl arm2 stove) (place spatula arm2 stove) (place salad-oil arm2 stove) (place measuring-cup arm2 stove) (place spoon arm2 stove)

  ;; todo
  (cond
   ((or (string= object "salad-oil") (string= object "oil"))
    (place-objects-on-table :object-name "あぶら" :arm :larm :spot-name spot)
    )
   ((string= object "bowl")
    (place-objects-on-table :object-name "ボウル1" :arm :rarm :spot-name spot)
    )
   ((string= object "small-bowl")
    (place-objects-on-table :object-name "ボウル0" :arm :rarm :spot-name spot)
    )
   ((string= object "spatula")
    (place-objects-on-table :object-name "ヘラ" :arm :rarm :spot-name spot)
    )
   ((string= object "broccoli")
    (place-objects-on-table :object-name "ブロッコリー" :arm :larm :spot-name spot)
    )
   ((string= object "pot")
    (place-objects-on-table :object-name "pot" :arm :larm :spot-name spot)
    )
   (t
    (format t "object ~A, arm ~A, spot ~A is not defined !!!~%" object arm spot)
    (return-from hold nil)
    )
   )
  )

(defun move-to (from to)
  (let (cmd-str)
    (setq cmd-str (format nil "(move-to ~A ~A) ~%" from to))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; (move-to stove kitchen) (move-to kitchen stove) (move-to kitchen sink) (move-to sink stove)
  (let ((move-suc-flag nil))
    (setq move-suc-flag (move-to-spot to))
    (format t "move-to result ~A ~%" move-suc-flag)
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

(defun turn-on-stove (vessel arm)
  (let (cmd-str)
    (setq cmd-str (format nil "(turn-on-stove ~A ~A) ~%" vessel arm))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  (cond
   ((or (string= vessel "frying-pan") (string= vessel "pan"))
    (start-ih :with-rec nil :left nil)
    )
   ((string= vessel "pot")
    (start-ih :with-rec nil :left t :max-power t)
    )
   (t
    (format t "vessel ~A and arm ~A is not defined !!!~%" vessel arm)
    (return-from turn-on-stove nil)
    )
   )
  )

(defun set-stove (before after vessel arm)
  (let (cmd-str)
    (setq cmd-str (format nil "(set-stove ~A ~A ~A ~A) ~%" before after vessel arm))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; TODO only rotate

  (cond ;; TODO Add for before and after state
   ((or (string= vessel "frying-pan") (string= vessel "pan"))
    (start-ih :with-rec nil :left nil :only-rotate t)
    )
   ((string= vessel "pot")
    (start-ih :with-rec nil :left t :only-rotate t)
    )
   (t
    (format t "vessel ~A and arm ~A is not defined !!!~%" vessel arm)
    (return-from turn-on-stove nil)
    )
   )
  )

(defun turn-off-stove (before vessel arm)
  (let (cmd-str)
    (setq cmd-str (format nil "(turn-off-stove ~A ~A ~A) ~%" before vessel arm))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  (cond
   ((or (string= vessel "frying-pan") (string= vessel "pan"))
    (stop-ih :with-rec nil :left nil)
    )
   ((string= vessel "pot")
    (stop-ih :with-rec nil :left t)
    )
   (t
    (format t "vessel ~A and arm ~A is not defined !!!~%" vessel arm)
    (return-from turn-off-stove nil)
    )
   )
  )

(defun wash (object arm)
  (let (cmd-str)
    (setq cmd-str (format nil "(wash ~A ~A) ~%" object arm))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )
  ;; TODO
  )

(defun pour (object vessel arm spot)
  (let (cmd-str)
    (setq cmd-str (format nil "(pour ~A ~A ~A ~A) ~%" object vessel arm spot))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; (pour milk bowl arm2 kitchen) (pour salad-oil frying-pan arm2 stove)

  ;; todo pour todo
  (cond
   ((and
     (or (string= object "salad-oil") (string= object "oil"))
     (string= vessel "frying-pan"))
    (pour-object-to-pan :from-object "あぶら" :to-object "フライパン" :arm :larm :spot-name spot)
    )
   ((and
     (string= object "broccoli")
     (string= vessel "pot"))
    (pour-object-to-pan :from-object "ブロッコリー" :to-object "鍋" :spot-name spot :arm :larm)
    )
   (t
    (format t "object ~A, arm ~A, spot ~A is not defined !!!~%" object arm spot)
    (return-from pour nil)
    )
   )
  )

(defun transfer (content from to arm spot)
  (let (cmd-str)
    (setq cmd-str (format nil "(transfer ~A ~A ~A ~A ~A) ~%" content from to arm spot))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; todo transfer todo
  (cond
   ((and
     (string= from "bowl")
     (string= to "frying-pan"))
    (pour-object-to-pan :from-object "ボウル1" :to-object "フライパン" :arm :rarm :spot-name spot)
    )
   ((and
     (string= from "small-bowl")
     (string= to "frying-pan"))
    (pour-object-to-pan :from-object "ボウル0" :to-object "フライパン" :arm :rarm :spot-name spot)
    )
   ((and
     (string= content "broccoli")
     (string= from "pot")
     (string= to "frying-pan"))
    (pour-object-to-pan :from-object "pot" :to-object "frying-pan" :spot-name spot :arm :larm)
    )
   (t
    (format t "from ~A, to ~A, arm ~A, spot ~A is not defined !!!~%" from to arm spot)
    (return-from transfer nil)
    )
   )
  )

(defun heat (object vessel state)
  (let (cmd-str)
    (setq cmd-str (format nil "(heat ~A ~A ~A) ~%" object vessel state))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; (heat butter frying-pan melted-butter) (heat salad-oil frying-pan thirty-seconds) (heat water pot boiling)

  ;; look frying-pan or pot
  ;; watch cook state recognition
  (cond
   ((string= vessel "frying-pan")
    (wait-cook-stove :object-name object :state state :vessel "フライパン")
    )
   ((string= vessel "pot")
    (wait-cook-stove :object-name object :state state :vessel "鍋")
    )
   (t
    (format t "vessel ~A is not defined !!!~%" vessel)
    (return-from heat nil)
    )
   )
  )

(defun cook (object state)
  (let (cmd-str)
    (setq cmd-str (format nil "(cook ~A ~A) ~%" object state))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; (cook egg-mixture half-cooked-egg) (cook egg heat-through)

  ;; look frying-pan
  (wait-cook-stove :object-name object :state state :vessel "フライパン")
  )

(defun boil (object state)
  (let (cmd-str)
    (setq cmd-str (format nil "(boil ~A ~A) ~%" object state))
    (format t "~A ~%" cmd-str)
    (speak-with-log (format nil "I do ~A" cmd-str) :lang "en")
    (pr2_cook_action_msg_pub :now-str cmd-str)
    )

  ;; (boil egg three-minutes)
  (wait-cook-stove :object-name object :state state :vessel "鍋")
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

  (cond
   ((and ;; TODO
     (string= input "egg-mixture")
     (string= vessel "frying-pan")
     )
    (stir-fry-cook-stove :object-name "egg-mixture" :vessel "フライパン" :tool "ヘラ" :state "soft-scrambled-egg" :spot "stove")
    )
   ((and ;; TODO
     (string= input "broccoli")
     (string= vessel "frying-pan")
     (string= tool "spatula")
     )
    (stir-fry-cook-stove :object-name input :vessel "フライパン" :tool "ヘラ" :state state :spot spot)
    )
   (t
    (format t "It is not defined now!! ~%")
    )
   )
  )

(defun fetch-water (arm)
  (format t "(fetch-water ~A) ~%" arm)
  ;; (fetch-water arm2)

  ;; rarm

  )

;; exec
(defun exec-cook-from-recipe (file-name)
  (load-planned-file file-name)
  (exec-plan-list)
  )

(format t "please run (exec-cook-from-recipe file-name) ~%")
