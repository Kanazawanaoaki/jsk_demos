(defun water-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/cook-with-primitive/bowl-use-kitchen-codes-with-primitive.l")
  
  ;; set objects
  (setq *veg* (make-cube 100 50 40))
  (send *veg* :set-color :green)
  
  ;; set global num
  (setq *s-time* 3)
  
  ;; (move-to-sink-irt)
  (move-to-spot-irt *sink-spot*)
  (objects (list *veg* *pr2* *scene* *mcup* *rcup*))
  (update-view)
  )

(water-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (grasp-lever) ~%")


;; def util-funcs
(defun reset-rarm ()
  (setq *rav0* (float-vector -25.6468 7.87241 -48.2704 -85.3763 253.675 -77.8887 -147.102))
  (move-arm-av *rav0* :arm :rarm) ;; move-arm primitive
  
  (setq *rav1* (float-vector -20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (move-arm-av *rav1* :arm :rarm) ;; move-arm primitive

  (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (move-arm-av *rav3* :arm :rarm) ;; move-arm primitive
  )

;; water funcs
(defun grasp-lever (&rest args &key (adjust 0) &allow-other-keys)
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :rotate-flag nil) ;; move-arm primitive
  
  ;;少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :rarm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate (float-vector -200 50 40) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :rotate (deg2rad 60) :x :world)

  (setq *tmp* (send *arrow* :copy-worldcoords)) ;; TODO 座標ベースにしたい_?
  
  (move-arm-ik (send *arrow* :copy-worldcoords)) ;; move-arm primitive
  
  ;;グリッパを微妙に開く
  (move-gripper-func 0.05 :arm :rarm) ;;move-gripper primitive
  
  ;; 水道のレバーの位置
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 adjust 0) :world)  
  (send *arrow* :translate #f(100 60 20) :world)
  
  (move-arm-ik (send *arrow* :copy-worldcoords)) ;; move-arm primitive

  (send *arrow* :translate #f(-100 -60 -20) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords)) ;; move-arm primitive

  (grasp-object) ;; grasp-object primitive
  
  (warn "please run (water-on) ~%") 
  )

(defun water-on ()
  ;; こことかも実はモデルをつくって開ける閉める動作にした方が良いのかな？という感じはする．
  ;; レバーを掴んでいる状態から
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 30) :world)

  (move-arm-ik (send *arrow* :copy-worldcoords) :rotate-flag nil) ;; move-arm primitive
  
  (warn "please run (water-off) ~%") 
  )


(defun water-off ()
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate #f(20 0 -50) :world)
  
  (move-arm-ik (send *arrow* :copy-worldcoords)) ;; move-arm primitive
  
  (warn "please run (release-lever) ~%")
  )

(defun release-lever ()
  ;;グリッパを微妙に開く
  (move-gripper-func 0.04 :arm :rarm) ;; move-gripper primitive
  
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate #f(100 60 20) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords)) ;; move-arm primitive
    
  (reset-rarm)
  )



;; wash vegitable funcs
(defun set-veg ()
  (if (not (eql (send *veg* :parent) nil))
      (send (send *veg* :parent) :dissoc *veg*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *veg* :copy-worldcoords) :rotate (deg2rad 30) :y))
    (send local-cds :assoc *veg*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *veg*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *veg*)
  )


(defun veg-set (coord)
  (send *arrow* :newcoords (send coord :copy-worldcoords))
  (send *arrow* :translate #f(80 0 -40) :world)
  (move-object-ik (send *arrow* :copy-worldcoords) :arm :larm :target *veg*) ;; move-object primitive
  
  (send *arrow* :translate #f(-80 0 40) :world)
  (move-object-ik (send *arrow* :copy-worldcoords) :arm :larm :target *veg* :rotate-flag :z) ;; move-object primitive
  )

(defun wash-veg-set ()
  (set-veg)
  
  ;; 洗う位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 20) :world)
  (send *arrow* :rotate (deg2rad -90) :z)  
  
  (veg-set (send *arrow* :copy-worldcoords))
  
  (warn "please water on ~%")
  )

(defun after-wash-veg-set ()
  (send *arrow* :newcoords (send *veg* :copy-worldcoords))
  (send *arrow* :translate #f(80 0 -40) :world)
  (move-object-ik (send *arrow* :copy-worldcoords) :arm :larm :target *veg*) ;; move-object primitive
  )

(defun after-wash ()
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 3)
    (send *pr2* :larm :move-end-pos #f(0 0 30) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    
    (send *pr2* :larm :move-end-pos #f(0 0 -30) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (move-arm-avs avs tms) ;; move-arm primitive
  
  (warn "please return to kitchen spot! ~%")
  )

(defun vegs-carry-pose ()
  (setq *lav-vc* #f(35.2692 -2.67452 58.1589 -95.2169 65.0479 -80.0523 -157.341))
  (move-arm-av *lav-vc* :arm :larm :times 8000) ;; move-arm primitive
  
  (warn "please go to kitchen spot !! ~%")  
  )


(defun now-wash-veg (&rest args &key (sleep-time 3) &allow-other-keys)
  (after-move-with-primitive)
  (wash-veg-set)
  
  (grasp-lever)
  (water-on)
  
  (unix:sleep sleep-time)
  
  (water-off)
  (release-lever)
  
  (after-wash-veg-set)
  (after-wash)
  (vegs-carry-pose)
  )
