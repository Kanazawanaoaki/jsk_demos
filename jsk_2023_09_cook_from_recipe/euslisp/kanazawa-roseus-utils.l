#!/usr/bin/env roseus

(require :arrow-object "models/arrow-object.l")

;; set objects
(unless (boundp '*arrow*)
  (progn
    (setq *arrow* (arrow))
    ))

(defun setq-arrows (&optional (num 3)) ;; TODO now |*arrow1*| のようになる
  (let ((arrow-name)
        (current-symbol))
    (dotimes (i num)
      (setq arrow-name (format nil "*arrow~A*" i))
      (setq current-symbol (intern arrow-name))
      (set current-symbol (arrow)))
    ))

;; ros init
(ros::roseus "kanazawa_roseus_utils" :anonymous t)
(unless (boundp '*tfl*)
  (setq *tfl* (instance ros::transform-listener :init))
  )
(unless (boundp '*tfb*)
  (setq *tfb* (instance ros::transform-broadcaster :init))
  )


;; IRT viewer
(defun reset-view-list ()
  (setq *view-objects* (list *arrow*))
  (format t "reset *view-objects* list !!~%")
  )

(unless (boundp '*view-objects*)
  (progn
    (reset-view-list)
    ))



;; ;; defun util fuction

;; set object
(defun dissoc-object (object-instance)
  (if (not (eql (send object-instance :parent) nil))
      (send (send object-instance :parent) :dissoc object-instance))
  )

;; (defun set-object (object-symbol coords file-path object-func)
;;   (unless (boundp '*arrow*)
;;     (progn
;;       (load file-path)
;;       (setq object-symbol (arrow))
;;       ))
;;   )
(defun set-object (object-symbol coords)
  (dissoc-object object-symbol)
  (send object-symbol :newcoords (send coords :copy-worldcoords))
  (unless (member object-symbol *view-objects*)
    (setq *view-objects* (append *view-objects* (list object-symbol))))
  )

;; calc coords
(defun calc-object-rel-coords (base-coords target-coords)
  (let ((rel-coords))
    (setq rel-coords (send (send base-coords :copy-worldcoords) :transformation (send target-coords :copy-worldcoords)))
    ;; (setq rel-coords (send (send (send base-coords :copy-worldcoords) :inverse-transformation) :transform (send target-coords :copy-worldcoords))) ;; これも同じ
    rel-coords))

(defun calc-coords-from-rel (base-coords rel-coords)
  (let ((target-coords))
    (setq target-coords (send (send base-coords :copy-worldcoords) :transform (send rel-coords :copy-worldcoords)))
    target-coords))

(defun calc-object-base-coords (target-coords rel-coords)
  (let ((base-coords))
    (setq base-coords (send (send (send target-coords :copy-worldcoords) :transformation (send rel-coords :copy-worldcoords) :world) :inverse-transformation))
    ;; (setq base-coords (send (send rel-coords :copy-worldcoords) :transformation (send target-coords :copy-worldcoords) :world)) ;; これも同じ
    ;; (setq base-coords (send (send target-coords :copy-worldcoords) :transformation (send rel-coords :copy-worldcoords) :world))
    ;; (setq base-coords (send (send (send rel-coords :copy-worldcoords) :transformation (send target-coords :copy-worldcoords) :world) :inverse-transformation)) ;; これも同じ
    base-coords))


(defun calc-rel-only-pos (ideal-coords rec-coords)
  (setq current-target-coords (make-coords :pos (send rec-coords :worldpos) :rot (send ideal-coords :worldrot))) ;; only use rec pos
  (setq ans (calc-object-rel-coords ideal-coords current-target-coords))
  ans)

(defun calc-diff-world-vec-from-rel (base-coords rel-coords)
  (setq ans-vec (v- (send base-coords :transform-vector (send rel-coords :worldpos)) (send base-coords :worldpos)))
  ans-vec)

;; adj coords offset
(defun set-offset-cds (target-cds offset-cds)
  (let (ans-cds)
    (setq ans-cds (send (send offset-cds :copy-worldcoords) :transform (send target-cds :copy-worldcoords)))
    ans-cds))

(defun inv-offset-cds (target-cds offset-cds)
  (let (ans-cds)
    ;; (setq ans-cds (send (send offset-cds :copy-worldcoords) :transform (send target-cds :copy-worldcoords)))
    (setq ans-cds (send (send (send offset-cds :copy-worldcoords) :inverse-transformation) :transform (send target-cds :copy-worldcoords)))
    ans-cds))

(defun calc-offset (rec-coords grasp-coords)
  (let (offset-coords)
    (setq offset-coords (send (send rec-coords :copy-worldcoords) :transformation (send grasp-coords :copy-worldcoords)))
    offset-coords))

(defun calc-average-two-coords (first-coords second-coords)
  (let (ans-coords)
    (setq ans-coords (make-coords :pos (scale 0.5 (v+ (send first-coords :worldpos) (send second-coords :worldpos)))
                                  :rot (send first-coords :worldrot)))
    ans-coords))

(defun calc-dis-two-coords (first-coords second-coords)
  (let (ans-dis)
    (setq ans-dis (norm (v- (send first-coords :worldpos) (send second-coords :worldpos))))
    ans-dis))

(defun analysis-cds-list (cds-list)
  (let ((x-list (list))
        (y-list (list))
        (z-list (list))
        )
    (dolist (cds cds-list)
      (setq x-list (append x-list (list (elt (send cds :worldpos) 0))))
      (setq y-list (append y-list (list (elt (send cds :worldpos) 1))))
      (setq z-list (append z-list (list (elt (send cds :worldpos) 2))))
      )
    (format t "x-list is ~A, x-max:~A, x-min:~A max-min-diff:~A ~%" x-list (apply #'max x-list) (apply #'min x-list) (- (apply #'max x-list) (apply #'min x-list)))
    (format t "y-list is ~A, y-max:~A, y-min:~A max-min-diff:~A ~%" y-list (apply #'max y-list) (apply #'min y-list) (- (apply #'max y-list) (apply #'min y-list)))
    (format t "z-list is ~A, z-max:~A, z-min:~A max-min-diff:~A ~%" z-list (apply #'max z-list) (apply #'min z-list) (- (apply #'max z-list) (apply #'min z-list)))
    ))

;; show cds
(defun publish-cds-tf (cds &key (base-frame "/base_footprint"))
  (send *tfb* :send-transform
        (send cds :copy-worldcoords) base-frame "/target_cds_frame")
  )

(defun publish-cds-tf-list (cds-list &key (base-frame "/base_footprint"))
  (let ((frame-name)
        (cds))
    (dotimes (i (length cds-list))
      (setq frame-name (format nil "/target_cds_frame_~A" i))
      (setq cds (elt cds-list i))
      (send *tfb* :send-transform
            (send cds :copy-worldcoords) base-frame frame-name)
      )
    ))

(defun show-cds-arrow (cds)
  (send *arrow* :newcoords (send cds :copy-worldcoords))
  (objects *arrow*)
  )

(defun print-cds-format (cds)
  (format t "(setq tmp-cds (make-coords :pos ~A :rot ~A)) ~%" (send cds :worldpos) (send cds :worldrot))
  )



