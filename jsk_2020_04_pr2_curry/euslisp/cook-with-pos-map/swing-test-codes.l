(defun swing-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

  ;; 揺するやつ
  (load "package://jsk_demo_common/euslisp/pr2-action.l")
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(swing-init)

(warn "~% there are swing funcs (grasp-swing-rarm) , (knife-touch-swing-set) , ~%")

;; add for sense




;; grasp swing
(defun grasp-swing-rarm (&rest args &key (times 10) &allow-other-keys)
  (set-pose)
  (setq *data-list* (list))
  
  ;; 開閉を繰り返す
  (dotimes (i times)
    (send *ri* :stop-grasp :rarm :wait t)
    (send *ri* :start-grasp :rarm :wait t)
    (setq data (send *ri* :state :gripper :rarm :position))
    (setq *data-list* (append *data-list* (list data)))
    )
  
  (print *data-list*)
  )

(defun grasp-swing-larm (&rest args &key (times 10) &allow-other-keys)
  (set-pose)
  (setq *data-list* (list))
  
  ;; 開閉を繰り返す  
  (dotimes (i times)
    (send *ri* :stop-grasp :larm :wait t)
    (send *ri* :start-grasp :larm :wait t)
    (setq data (send *ri* :state :gripper :larm :position))
    (setq *data-list* (append *data-list* (list data)))
    )
  
  (print *data-list*)
  )

(defun tool-grasp-swing (&rest args &key (times 10) &allow-other-keys)
  (set-pose)
  (setq *data-list* (list))
  
  ;; 開閉を繰り返す
  (dotimes (i times)
    (send *ri* :stop-grasp :rarm :wait t)
    (send *ri* :speak-jp "包丁を握らせて下さい")
    (unix:sleep *s-time*)
    (send *ri* :start-grasp :rarm :wait t)
    (setq data (send *ri* :state :gripper :rarm :position))
    (setq *data-list* (append *data-list* (list data)))
    )
  
  (print *data-list*)
  )



;; knife swing
(defun set-knife-hor ()
  (if (not (eql (send *knife* :parent) nil))
      (send (send *knife* :parent) :dissoc *knife*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *knife* :copy-worldcoords))
    (send local-cds :assoc *knife*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *knife*)
    )
  (send *knife* :translate #f(20 0 0))  
  (send *knife* :rotate (deg2rad 90) :x)
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *knife*)
  )

(defun knife-touch-swing-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  (set-pose)
  
  (send *pr2* :rarm :angle-vector #f(-18.9384 37.606 -71.146 -119.05 171.694 -97.0758 -210.914))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; 包丁を受け取る
  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)
  
  ;; 揺すられるまで待つ．
  (wait-for-hand-impact :larm)
  
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  (set-knife-hor)
  
  (warn "please start recording rosbag and run (knife-touch-swing) ~%")
  )


(defun knife-touch-swing ()
  ;; (send *pr2* :rarm :angle-vector #f(-23.882 43.9692 -83.1067 -112.404 163.298 -86.8432 -202.998))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *knife* :attention-attention0) :copy-worldcoords))
  
  (setq interval 10)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (11))
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please finish recording rosbad and run (after-knife-swing) ~%")
  )

(defun after-knife-swing ()
  ;; 包丁を離す
  (send *ri* :speak-jp "包丁を離します")
  (unix:sleep *s-time*)
  (send *ri* :stop-grasp :rarm)  
  (if (not (eql (send *knife* :parent) nil))
      (send (send *knife* :parent) :dissoc *knife*))
  )


(defun slide-knife-swing-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  (set-pose)
  
  ;; (send *pr2* :rarm :angle-vector #f(-18.9384 37.606 -71.146 -119.05 171.694 -97.0758 -210.914))
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector))
  ;; (send *ri* :wait-interpolation)
  
  ;; (set-knife-hor)
  
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 500 8550 30880) :rpy (float-vector -3.142 0.244 0.0)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       *arrow*
  ;;       :move-target (car (send *knife* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view nil)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector))
  ;; (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector #f(-19.5244 38.4053 -72.5949 -118.484 170.698 -95.9465 -210.062))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; 包丁を受け取る
  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)
  
  ;; 揺すられるまで待つ．
  (wait-for-hand-impact :larm)
  
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  (set-knife-hor) 
  
  (warn "please start recording rosbag and run (slide-knife-swing) ~%")
  )

(defun slide-knife-swing ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *knife* :attention-attention0) :copy-worldcoords))
  
  (setq interval 5)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ 50 interval)) 1))
    (send *arrow* :translate (float-vector 0 (* interval -1) 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view *debug-flag*)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (warn "please finish recording rosbad and run (after-knife-swing) ~%")
  )



;; peeler swing
(defun set-peeler-hor ()
  (if (not (eql (send *peeler* :parent) nil))
      (send (send *peeler* :parent) :dissoc *peeler*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *peeler* :copy-worldcoords))
    (send local-cds :assoc *peeler*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *peeler*)
    )
  (send *peeler* :rotate (deg2rad 90) :x)
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *peeler*)
  )

(defun peeler-swing-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  (set-pose)
  
  (send *pr2* :rarm :angle-vector #f(-27.6361 -13.2569 -74.5467 -60.3697 -37.8241 -72.4582 396.357))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; ピーラーを受け取る
  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "ピーラーを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)
  
  ;; 揺すられるまで待つ．
  (wait-for-hand-impact :larm)
  
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  (set-peeler)
  
  (warn "please start recording rosbag and run (peeler-swing) ~%")  
  )

(defun peeler-swing ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *knife* :attention-attention0) :copy-worldcoords))
  
  (setq interval 10)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (11))
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *peeler* :attention))
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please finish recording rosbad and run (after-peeler-swing) ~%")
  )

(defun after-peeler-swing ()
  ;; ピーラーを離す
  (send *ri* :speak-jp "ピーラーを離します")
  (unix:sleep *s-time*)
  (send *ri* :stop-grasp :rarm)  
  (if (not (eql (send *peeler* :parent) nil))
      (send (send *peeler* :parent) :dissoc *peeler*))
  )

;; ;; potato peeler funcs
;; (defun set-peeler-hor ()
;;   (if (not (eql (send *peeler* :parent) nil))
;;       (send (send *peeler* :parent) :dissoc *peeler*))
;;   (let (local-cds)
;;     (setq local-cds (make-cascoords))
;;     (send local-cds :newcoords (send *peeler* :copy-worldcoords))
;;     (send local-cds :assoc *peeler*)
;;     (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
;;     (send local-cds :dissoc *peeler*)
;;     )
;;   (send *peeler* :rotate (deg2rad 90) :x)
;;   (send *viewer* :draw-objects)
;;   (send (send *pr2* :rarm :end-coords) :assoc *peeler*)
;;   )

;; (defun peeler-swing-set ()
;;   (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
;;   (set-pose)
  
;;   (send *pr2* :rarm :angle-vector #f(-27.6361 -13.2569 -74.5467 -60.3697 -37.8241 -72.4582 396.357))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
  
;;   ;; ピーラーを受け取る
;;   (send *ri* :stop-grasp :rarm)
;;   (send *ri* :speak-jp "ピーラーを握らせて下さい")
;;   (unix:sleep *s-time*)
;;   (send *ri* :start-grasp :rarm :wait t)
  
;;   ;; 揺すられるまで待つ．
;;   (wait-for-hand-impact :larm)
  
;;   (send *ri* :start-grasp :rarm :wait t :gain 100)
;;   (set-peeler)
  
;;   (warn "please start recording rosbag and run (peeler-swing) ~%")  
;;   )

;; (defun peeler-swing ()
;;   (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
;;   (send *arrow* :newcoords (send (send *knife* :attention-attention0) :copy-worldcoords))
  
;;   (setq interval 10)
  
;;   (setq avs (list))
;;   (setq tms (list))
  
;;   (dotimes (i (11))
;;     (send *arrow* :translate (float-vector 0 0 (* interval -1)))
;;     (send *pr2* :rarm :inverse-kinematics
;;           *arrow*
;;           :move-target (car (send *peeler* :attention))
;;           :rotation-axis t
;;           :debug-view nil)
    
;;     (setq av (send *pr2* :angle-vector))
    
;;     (setq avs (append avs (list av)))
;;     (setq tms (append tms (list 600)))
;;     )
  
;;   (send *ri* :angle-vector-sequence avs tms)
;;   (send *ri* :wait-interpolation)
  
;;   (warn "please finish recording rosbad and run (after-peeler-swing) ~%")
;;   )

;; (defun after-peeler-swing ()
;;   ;; ピーラーを離す
;;   (send *ri* :speak-jp "ピーラーを離します")
;;   (unix:sleep *s-time*)
;;   (send *ri* :stop-grasp :rarm)  
;;   (if (not (eql (send *peeler* :parent) nil))
;;       (send (send *peeler* :parent) :dissoc *peeler*))
;;   )


;; push button
(defun push-microwave-button-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/microwave-codes.l")
  
  (send *pr2* :angle-vector #f(100.161 75.0006 49.9994 109.993 -109.995 -19.9972 -10.0007 -9.99948 -2.48922 58.5552 -14.6294 -110.317 167.46 -52.9349 -74.6765 -0.005299 51.906))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; グリッパを閉じる
  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please start recording rosbag and run (push-microwave-button) ~%")  
  )

(defun push-microwave-button ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))

  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *pr2* :rarm :move-end-pos #f(10 0 0))
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please finish recording rosbad ~%")
  )



(defun push-ih-on-button-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")

  (set-pose)
  (set-pose-3)
  
  (send *pr2* :larm :angle-vector #f(95.1083 74.2553 108.75 -98.3809 248.66 -20.6971 -176.265))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; グリッパを閉じる
  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please start recording rosbag and run (push-ih-button) ~%")  
  )


(defun push-ih-knob-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")

  (set-pose)
  (set-pose-3)
  
  (send *pr2* :larm :angle-vector #f(96.2573 74.2503 108.381 -91.8139 267.07 -17.7686 -195.775))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; グリッパを閉じる
  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please start recording rosbag and run (push-ih-button) ~%")  
  )


(defun push-ih-button ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *pr2* :larm :move-end-pos #f(-10 0 0) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please finish recording rosbad ~%")
  )


(defun push-shelf-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  (send *pr2* :rarm :angle-vector #f(7.65504 -2.50971 -7.07688 -75.6546 -187.512 -79.1952 188.545))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)
  
  (warn "please start recording rosbag and run (push-microwave-button) ~%")  
  )

(defun push-shelf ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 12)
    (send *arrow* :translate (float-vector -10 0 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please finish recording rosbad ~%")
  )


;; spatula squeeze
(defun set-spatula-hor ()
  (if (not (eql (send *spatula* :parent) nil))
      (send (send *spatula* :parent) :dissoc *spatula*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *spatula* :copy-worldcoords))
    (send local-cds :assoc *spatula*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *spatula*)
    )
  (send *spatula* :rotate (deg2rad 90) :x)
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *spatula*)
  )

(defun squeeze-swing-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  
  (set-pose)
  
  (send *pr2* :rarm :angle-vector #f(-4.85911 4.80276 -91.7891 -58.8883 -712.761 -21.1501 348.83))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  ;; ヘラを受け取る
  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "ヘラを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)
  
  ;; 揺すられるまで待つ．
  (wait-for-hand-impact :larm)
  
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  (set-spatula)
  
  (warn "please start recording rosbag and run (peeler-swing) ~%")  
  )

(defun squeeze-swing ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (elt (send *spatula* :attention) 1) :copy-worldcoords))
  
  (setq interval 10)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (15))
    (send *arrow* :translate (float-vector 0 -10 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (elt (send *spatula* :attention) 1)
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please finish recording rosbad and run (after-peeler-swing) ~%")
  )

(defun after-squeeze-swing ()
  ;; ヘラを離す
  (send *ri* :speak-jp "ヘラを離します")
  (unix:sleep *s-time*)
  (send *ri* :stop-grasp :rarm)  
  (if (not (eql (send *spatula* :parent) nil))
      (send (send *spatula* :parent) :dissoc *spatula*))
  )


