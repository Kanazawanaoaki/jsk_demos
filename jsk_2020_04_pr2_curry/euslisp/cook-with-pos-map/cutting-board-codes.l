(defun cutting-board-init ()
  ;; init
  (load "move-to-kitchen-with-map.l")
  
  ;; set objects
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  
  ;; def global-coords
  (setq *slide-rarm-coords* (make-coords :pos (float-vector 430.297 8421.198 30852.165) :rpy (float-vector -3.086 1.155 3.132)))
  (setq *slide-larm-coords* (make-coords :pos (float-vector 735.864 8441.372 30866.716) :rpy (float-vector 2.244 -1.518 0.872)))
  (setq *grasp-larm-coords* (make-coords :pos (float-vector 679.695 8281.493 30832.711) :rpy (float-vector 1.882 0.065 1.548)))  
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *cutting-board*))
  (update-view)  
  )

(cutting-board-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (slide-board-set) ~%")


;; def util-funcs
(defun reset-rarm ()
  (setq *rav0* (float-vector -25.6468 7.87241 -48.2704 -85.3763 253.675 -77.8887 -147.102))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  (setq *rav1* (float-vector -20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (setq *rav2* (float-vector -30.0303 1.63624 -169.166 -116.783 100.843 -98.3015 -58.1037))
  ;; (send *pr2* :rarm :angle-vector *rav2*)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  ;; (send *ri* :wait-interpolation)

  (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *pr2* :rarm :angle-vector *rav3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  (setq *lav1* (float-vector 16.6498 -20.1996 123.812 -51.9785 -42.6397 -65.2851 -0.059116))
  (send *pr2* :larm :angle-vector *lav1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (setq *lav2* (float-vector 41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -0.0))
  (send *pr2* :larm :angle-vector *lav2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *lav3* (float-vector 75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -0.0))
  (send *pr2* :larm :angle-vector *lav3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  

  (setq *lav4* (float-vector 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  

  )


;; def funcs
(defun slide-board-set ()
  ;; slide時の左腕待機座標
  (send *arrow* :newcoords (send *slide-larm-coords* :copy-worldcoords))

  (send *ri* :start-grasp :larm :wait t)
  
  (send *arrow* :translate #f(50 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-50 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :rarm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate (float-vector -200 50 50) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :rotate (deg2rad 60) :x :world)  
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  ;; slideを始める位置
  (send *arrow* :newcoords (send *slide-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate #f(-10 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(10 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (warn "please run (slide-board) ~%")
  )

(defun slide-board ()
  (setq avs (list))
  (setq tms (list))

  (dotimes (i 10)
    (send *pr2* :rarm :move-end-pos #f(10 0 0) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (warn "please run (after-slide) ~%")
  )

(defun after-slide ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(-10 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (reset-rarm)

  (send *pr2* :larm :move-end-pos #f(50 0 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 -200 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)  
  (send *ri* :wait-interpolation)

  (warn "please run (grasp-board) ~%")
  )

(defun grasp-board ()
  ;; 掴む位置
  (send *arrow* :newcoords (send *grasp-larm-coords* :copy-worldcoords))

  (send *arrow* :translate #f(35 -100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)
  
  (send *arrow* :translate #f(-35 100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)
  
  (warn "please run (lift-board) ~%")
  )


;; tmp
(defun recieve-cutting-board ()
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
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8361 31167) :rpy (float-vector 0 0 0)))
  ;; (send *arrow* :rotate (deg2rad 90) :z :world)
  ;; (send *arrow* :rotate (deg2rad -90) :x)
  ;; (send *pr2* :larm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:rotation-axis t
  ;; 	:debug-view *debug-flag*)
  ;; (setq *tmp-av* (send *pr2* :rarm :angle-vector))
  (send *pr2* :larm :angle-vector #f(36.6648 -20.175 113.68 -74.3369 -35.515 -61.5521 -162.125))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "まな板を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)
  
  (warn "please run (put-cutting-board) ~%")
  )

(defun put-cutting-board ()
  ;; まな板を置く，スライドさせてヘリに当てる等をする？
  
  
  
  )

(defun push-board-set ()
  ;; 右手をセットするなどして準備をする．
  
  )

(defun push-board-1 ()
  ;; 天板に左腕が当たるまで動作をさせ続ける．

  
  )

(defun push-board-2 ()
  ;; 天板に当たったら，次は上からスライドさせるようにする．
  
  
  )



(defun lift-board ()
  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )


(defun now-board ()
  (slide-board-set)
  (slide-board)
  (after-slide)
  (grasp-board)
  (lift-board)
  )
