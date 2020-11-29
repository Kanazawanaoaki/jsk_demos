(defun tool-init ()
  ;; init
  (load "move-to-kitchen-with-map.l")

  ;; set tools
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/knife-new-attention.l")
  (setq *knife* (knife))
  (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/peeler.l")
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send *peeler-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-peeler.l")
  (setq *potato-peeler* (peeler))
  (send *potato-peeler* :newcoords (send *potato-peeler-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/spatula.l")
  (setq *spatula* (spatula))
  (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords)) ;; tmp 本来は棚の中想定

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/ladle.l")
  (setq *ladle* (ladle))
  (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords)) ;; tmp 本来は棚の中想定

  ;; set equipment
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/shelf-door.l")
  (setq *shelf-door* (shelf-door))
  (send *shelf-door* :newcoords (send *shelf-door-coords* :copy-worldcoords))

  (move-to-kitchen-irt)
  (objects (list *pr2* *peeler* *knife* *potato-peeler* *scene* *spatula* *ladle* *shelf-door*))
  (update-view)

  )

(tool-init)


;; set codes
(warn "~%  If you use real robot, run (update-pos) ~%")
(warn "please run (now-set-tools) or (set-knife) ~%")

(defun receive-knife ()
  ;; knifeの位置
  (send *arrow* :newcoords (send *knife-coords* :copy-worldcoords))
  (send *arrow* :translate #f(-12 0 0))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "包丁を握らせて下さい")

  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *knife* :translate #f(12 0 0))
  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)
  (send *viewer* :draw-objects)

  (warn "please run (put-knife) ~%")
  )

(defun put-knife ()  
  (send *arrow* :newcoords (send *knife-coords* :copy-worldcoords))
  (send *arrow* :translate #f(-12 0 0))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-60 0 -100) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :move-gripper :rarm 0.08)
  (send *pr2* :rarm :end-coords :dissoc *knife*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(60 -150 170) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (receive-peeler) ~%")
  )

(defun receive-peeler ()
  ;;掴む位置
  (send *arrow* :newcoords (send *peeler-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "ピーラーを握らせて下さい")

  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *peeler* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *peeler*)
  (send *viewer* :draw-objects)

  (warn "please run (put-peeler) ~%")
  )

(defun put-peeler ()
  (send *arrow* :newcoords (send *peeler-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-60 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :move-gripper :rarm 0.08)
  (send *pr2* :rarm :end-coords :dissoc *peeler*)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (receive-potato-peeler) ~%")
  )

(defun receive-potato-peeler ()
  ;;掴む位置
  (send *arrow* :newcoords (send *potato-peeler-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "じゃがいもピーラーを握らせて下さい")

  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (send *potato-peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *potato-peeler* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *potato-peeler*)
  (send *viewer* :draw-objects)

  (warn "please run (put-potato-peeler) ~%")
  )


(defun put-potato-peeler ()
  (send *arrow* :newcoords (send *potato-peeler-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-60 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :move-gripper :rarm 0.08)
  (send *pr2* :rarm :end-coords :dissoc *potato-peeler*)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-rarm) ~%")
  )


(defun receive-spatula ()
  ;; spatulaの位置
  (send *arrow* :newcoords (send *spatula-coords-1* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "ヘラを握らせて下さい")

  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (send *spatula* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *spatula* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *spatula*)
  (send *viewer* :draw-objects)

  (warn "please run (put-spatula-1) or (put-spatula-0) ~%")
  )

(defun put-spatula-1 ()  
  (send *arrow* :newcoords (send *spatula-coords-1* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *arrow* :translate #f(60 0 100) :world)
  (send *ri* :wait-interpolation)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-60 0 -100) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :move-gripper :rarm 0.08)
  (send *pr2* :rarm :end-coords :dissoc *spatula*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(60 -150 170) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun receive-ladle ()
  ;; ladleの位置
  (send *arrow* :newcoords (send *ladle-coords-1* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "おたまを握らせて下さい")

  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (send *ladle* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *ladle* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *ladle*)
  (send *viewer* :draw-objects)

  (warn "please run (put-ladle-1) or (put-ladle-0) ~%")
  )

(defun put-ladle-1 ()  
  (send *pr2* :larm :angle-vector #f(117.007 48.3805 113.439 -103.326 38.7107 -5.72958 14.4628))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (send *ladle-coords-1* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-60 0 -100) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :move-gripper :rarm 0.08)
  (send *pr2* :rarm :end-coords :dissoc *ladle*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(60 100 170) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )

(defun rarm-middle-pose ()
  ;; 中間姿勢になる
  (send *arrow* :newcoords (make-coords :pos (float-vector 570 8500 31100) :rpy (float-vector 3.14 0.0 0.0)))
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun open-shelf-set ()
  ;; 中間姿勢になる
  (rarm-middle-pose)
  
  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)
  
  ;; 棚のノブの位置
  ;; (send *arrow* :newcoords (send *shelf-knob-closed-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (car (send *shelf-door* :handle)) :copy-worldcoords))
  
  (send *arrow* :translate (float-vector 100 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; ノブのところまで手を伸ばす 力覚を入れても良い．
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 10)
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

  ;; (send *arrow* :newcoords)
  

  ;; (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please run (open-shelf) ~%")
  )

(defun open-shelf ()
  (let ((i 0)   ;; open
	(handle-coords (make-coords))
	(av)
	(tms (list))
	(avs (list)))
    (while (< i 99) 
      (send *shelf-door* :angle-vector (float-vector i))
      (send handle-coords :newcoords (send (car (send *shelf-door* :handle)) :copy-worldcoords))
      
      (send *pr2* :rarm :inverse-kinematics (send handle-coords :copy-worldcoords) :rotation-axis t)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 600)))
      
      (setq i (+ i 10))
      )
    (send *ri* :angle-vector-sequence avs tms)
    (send *ri* :wait-interpolation)
    )
  (warn "please run (after-open) ~%")
  )

(defun after-open ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *pr2* :rarm :move-end-pos #f(0 20 -60) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; 中間姿勢になる
  (rarm-middle-pose)
  
  (warn "please run (grasp-spatula-0) ~%")
  )

(defun close-shelf-set ()
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)

  (send *shelf-door* :angle-vector (float-vector 100))

  (send *arrow* :newcoords (send (car (send *shelf-door* :handle)) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -70) :y)
  (send *arrow* :translate #f(-60 0 60))

  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(60 0 0))
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -60))
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (close-shelf) ~%")
  )

(defun close-shelf ()
  (let ((i 100)   ;; close
	(handle-coords (make-coords))
	(av)
	(tms (list))
	(avs (list)))
    (while (>= i 0) 
      (send *shelf-door* :angle-vector (float-vector i))
      (send handle-coords :newcoords (send (car (send *shelf-door* :handle)) :copy-worldcoords))
      (send handle-coords :rotate (deg2rad -70) :y)
      
      (send *pr2* :rarm :inverse-kinematics (send handle-coords :copy-worldcoords) :rotation-axis t)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 1000)))
      
      (setq i (- i 10))
      )
    (send *ri* :angle-vector-sequence avs tms)
    (send *ri* :wait-interpolation)
    )
  (warn "please run (after-close) ~%")
  )

(defun after-close ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(80 0 -80) :world) 
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 中間姿勢になる
  (rarm-middle-pose)

  (reset-rarm)
  )



(defun grasp-tool-on-shelf ()
  ;; arrow　はセットしてある前提

  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)

  (send *arrow* :translate #f(120 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-60 0 30) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-60 0 -30) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  (send *ri* :start-grasp :rarm :wait t)
  )

(defun grasp-spatula-0 ()  
  ;; 中間姿勢になる
  (rarm-middle-pose)

  (send *spatula* :newcoords (send *spatula-coords-0* :copy-worldcoords))
  (send *arrow* :newcoords (send *spatula* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  (grasp-tool-on-shelf)
  (send (send *pr2* :rarm :end-coords) :assoc *spatula*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(30 0 30) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手をスライドさせる
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 35)
    (send *arrow* :translate (float-vector 10 0 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  ;; 手を下げる
  (send *pr2* :rarm :move-end-pos #f(0 0 -60) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; 中間姿勢になる
  (rarm-middle-pose)

  (warn "please run (put-spatula-1) ~%")
  )

(defun grasp-ladle-0 ()
  ;; 中間姿勢になる
  (rarm-middle-pose)
  
  (send *ladle* :newcoords (send *ladle-coords-0* :copy-worldcoords))
  (send *arrow* :newcoords (send *ladle* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  (grasp-tool-on-shelf)
  (send (send *pr2* :rarm :end-coords) :assoc *ladle*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(20 0 20) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手をスライドさせる
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 35)
    (send *arrow* :translate (float-vector 10 0 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  ;; 手を下げる
  (send *pr2* :rarm :move-end-pos #f(0 0 -60) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; 中間姿勢になる
  (rarm-middle-pose)

  (warn "please run (put-ladle-1) ~%")  
  )

(defun put-spatula-0 ()
  ;; 中間姿勢になる
  (rarm-middle-pose)

  ;; spatulaを置く位置
  (send *arrow* :newcoords (send *spatula-coords-0* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  (send *arrow* :translate #f(30 0 30) :world)
  (send *arrow* :translate (float-vector 350 0 0) :world)
  (send *arrow* :translate #f(0 0 -100) :world)

  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手をスライドさせる
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 35)
    (send *arrow* :translate (float-vector -10 0 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-30 0 -30) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.07)
  (send *pr2* :rarm :end-coords :dissoc *spatula*)

  (send *arrow* :translate #f(60 0 30) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(60 0 -30) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  ;; 中間姿勢になる
  (rarm-middle-pose)
  )

(defun put-ladle-0 ()
  ;; 中間姿勢になる
  (rarm-middle-pose)
  
  ;; ladleを置く位置
  (send *arrow* :newcoords (send *ladle-coords-0* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  (send *arrow* :translate #f(30 0 30) :world)
  (send *arrow* :translate (float-vector 350 0 0) :world)
  (send *arrow* :translate #f(0 0 -100) :world)

  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手をスライドさせる
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 35)
    (send *arrow* :translate (float-vector -10 0 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-30 0 -30) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.07)
  (send *pr2* :rarm :end-coords :dissoc *ladle*)

  (send *arrow* :translate #f(60 0 30) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(60 0 -30) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  ;; 中間姿勢になる
  (rarm-middle-pose)
  )



(defun reset-rarm ()
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (setq *rav2* #f(-30.0303 1.63624 -169.166 -116.783 100.843 -98.3015 -58.1037))
  (send *pr2* :rarm :angle-vector *rav2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (setq *rav3* #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *pr2* :rarm :angle-vector *rav3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun up-rarm ()
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

;; grasp-codes
(defun grasp-tool-on-table ()
  ;; arrow　はセットしてある前提
  (send *ri* :stop-grasp :rarm :wait t)

  (send *arrow* :translate #f(50 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-50 0 -100) :world)  
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  (send *ri* :start-grasp :rarm :wait t)
  )


(defun grasp-knife ()
  (up-rarm)

  ;;掴む位置
  (send *arrow* :newcoords (send *knife* :copy-worldcoords))
  (send *arrow* :translate #f(-12 0 0))
  (send *arrow* :rotate (deg2rad -90) :x)

  ;; つかむ
  (grasp-tool-on-table)  
  (send (send *pr2* :rarm :end-coords) :assoc *knife*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(40 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun grasp-peeler ()
  (up-rarm)
  
  ;;掴む位置
  (send *arrow* :newcoords (send *peeler* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; つかむ
  (grasp-tool-on-table)  
  (send (send *pr2* :rarm :end-coords) :assoc *peeler*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(40 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun grasp-potato-peeler ()
  (up-rarm)

  ;;掴む位置
  (send *arrow* :newcoords (send *potato-peeler* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)

  ;; つかむ
  (grasp-tool-on-table)  
  (send (send *pr2* :rarm :end-coords) :assoc *potato-peeler*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(40 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )


(defun grasp-spatula ()
  (up-rarm)
  
  ;;掴む位置
  (send *arrow* :newcoords (send *spatula* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; つかむ
  (grasp-tool-on-table)  
  (send (send *pr2* :rarm :end-coords) :assoc *spatula*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(40 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 待機姿勢になる
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun grasp-ladle ()
  (send *pr2* :larm :angle-vector #f(117.007 48.3805 113.439 -103.326 38.7107 -5.72958 14.4628))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (up-rarm)
  
  ;;掴む位置
  (send *arrow* :newcoords (send *ladle* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; つかむ
  (grasp-tool-on-table)  
  (send (send *pr2* :rarm :end-coords) :assoc *ladle*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(40 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 待機姿勢になる
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

;; set codes
(defun set-spatula ()
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

(defun set-ladle ()
  (if (not (eql (send *ladle* :parent) nil))
      (send (send *ladle* :parent) :dissoc *ladle*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *ladle* :copy-worldcoords))
    (send local-cds :assoc *ladle*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *ladle*)
    )
  (send *ladle* :rotate (deg2rad 90) :x)
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *ladle*)
  )

(defun set-knife ()
  (if (not (eql (send *knife* :parent) nil))
      (send (send *knife* :parent) :dissoc *knife*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *knife* :copy-worldcoords))
    (send local-cds :assoc *knife*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *knife*)
    )
  (send *knife* :translate #f(12 0 0))
  (send *knife* :rotate (deg2rad 90) :x)
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *knife*)
  )

(defun set-peeler ()
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

(defun set-potato-peeler ()
  (if (not (eql (send *potato-peeler* :parent) nil))
      (send (send *potato-peeler* :parent) :dissoc *potato-peeler*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *potato-peeler* :copy-worldcoords))
    (send local-cds :assoc *potato-peeler*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *potato-peeler*)
    )
  (send *potato-peeler* :rotate (deg2rad 90) :x)
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *potato-peeler*)
  )



;; now codes
(defun now-set-tools ()
  ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  (up-rarm)
  (receive-knife)
  (put-knife)
  (receive-peeler)
  (put-peeler)
  (receive-potato-peeler)
  (put-potato-peeler)  
  )

(defun now-set-knife ()
  (up-rarm)
  (receive-knife)
  (put-knife)
  )

(defun now-set-peeler ()
  (up-rarm)
  (receive-peeler)
  (put-peeler)  
  )

(defun now-set-potato-peeler ()
  (up-rarm)
  (receive-potato-peeler)
  (put-potato-peeler)  
  )

(defun now-set-spatula-1 ()
  (up-rarm)
  (receive-spatula)
  (put-spatula-1)
  )

(defun now-set-ladle-1 ()
  (up-rarm)
  (receive-ladle)
  (put-ladle-1)
  )


(defun now-set-spatula-0 ()
  (up-rarm)
  (receive-spatula)
  (put-spatula-0)
  )

(defun now-set-ladle-0 ()
  (up-rarm)
  (receive-ladle)
  (put-ladle-0)
  )


(defun now-set-in-shelf ()
  ;; 棚の中におたまとヘラをセットする．
  (open-shelf-set)
  (oepn-shelf)
  (after-open)

  (receive-spatula)
  (put-spatula-0)
  (receive-ladle)
  (put-ladle-0)

  (close-shelf-set)
  (close-shelf)
  (after-close)
  )

(defun now-set-from-shelf ()
  (open-shelf-set)
  (oepn-shelf)
  (after-open)

  (grasp-spatula-0)
  (put-spatula-1)
  (grasp-ladle-0)
  (put-ladle-1)
  
  (close-shelf-set)
  (close-shelf)
  (after-close)
  )

(defun now-set-tool-1 ()
  (now-set-spatula-1)
  (now-set-ladle-1)
  )
