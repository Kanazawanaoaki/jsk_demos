(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/cooking-exec-pddl-utils.l")


;; defun codes for test

(defun hold (object arm spot)
  (format t "(hold ~A ~A ~A) ~%" object arm spot)
  )

(defun place (object arm spot)
  (format t "(place ~A ~A ~A) ~%" object arm spot)
  )

(defun move-to (from to)
  (format t "(move-to ~A ~A) ~%" from to)
  )

(defun open-tap (arm)
  (format t "(open-tap ~A) ~%" arm)
  )

(defun close-tap (arm)
  (format t "(close-tap ~A) ~%" arm)
  )

(defun turn-on-stove (arm)
  (format t "(turn-on-stove ~A) ~%" arm)
  )

(defun set-stove (before after arm)
  (format t "(set-stove ~A ~A ~A) ~%" before after arm)
  )

(defun turn-off-stove (before arm)
  (format t "(turn-off-stove ~A ~A) ~%" before arm)
  )

(defun wash (object arm)
  (format t "(wash ~A ~A) ~%" object arm)
  )

(defun pour (object vessel arm spot)
  (format t "(pour ~A ~A ~A ~A) ~%" object vessel arm spot)
  )

(defun transfer (content from to arm spot)
  (format t "(transfer ~A ~A ~A ~A ~A) ~%" content from to arm spot)
  )

(defun heat (object vessel state)
  (format t "(heat ~A ~A ~A) ~%" object vessel state)
  )

(defun cook (object state)
  (format t "(cook ~A ~A) ~%" object state)
  )

(defun boil (object state)
  (format t "(boil ~A ~A) ~%" object state)
  )

(defun stir (object tool vessel state spot arm)
  (format t "(stir ~A ~A ~A ~A ~A ~A) ~%" object tool vessel state spot arm)
  )

(defun mix (mixture ing-one ing-two vessel tool spot arm1 arm2)
  (format t "(mix ~A ~A ~A ~A ~A ~A ~A ~A) ~%" mixture ing-one ing-two vessel tool spot arm1 arm2)
  )

(defun stir-fry (input vessel tool state spot arm1 arm2)
  (format t "(stir-fry ~A ~A ~A ~A ~A ~A ~A) ~%" input vessel tool state spot arm1 arm2)
  )

(defun fetch-water (arm)
  (format t "(fetch-water ~A) ~%" arm)
  )
