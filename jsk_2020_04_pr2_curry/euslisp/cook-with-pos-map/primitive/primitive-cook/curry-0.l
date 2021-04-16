;; 準備のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-0 () ;; 準備をする．  

  ;; 棚の中にヘラとおたまをセットする
  (curry-0-1-set-in-shelf)
  
  ;; ボウル１をセットする
  (curry-0-2-set-bowl-1)
  
  ;; 野菜をセットする？
  (curry-0-3-set-vegs)
  
  ;; 計量カップはここでセットする？
  (curry-0-4-set-mcup)
  
  ;; コンロの前まで移動する
  (curry-0-5-move-to-stove)
  
  ;; ボウル２・３をセットする
  (curry-0-6-set-bowl-2-3)
  
  ;; キッチンの前に戻る
  (curry-0-7-move-to-kitchen)
  
  ;; まな板をセットする
  (curry-0-8-set-board)
  
  ;; 道具３つをセットする
  (curry-0-9-set-tools-on-table)
  )


(defun curry-0-1-set-in-shelf ()  ;; 棚の中にヘラとおたまをセットする
  
  ;; 棚の扉を開ける
  (curry-0-1-1-open-shelf)
  
  ;; ヘラをセットする
  (curry-0-1-2-set-spatula)

  ;; おたまをセットする
  (curry-0-1-3-set-ladle)

  ;; 棚の扉を閉める
  (curry-0-1-4-close-shelf)
  )

(defun curry-0-1-1-open-shelf ()   ;; 棚の扉を開ける
  
  ;; 棚の方を見る look-at-shelf
  (move-head-look-at-coords *shelf-look-coords*)
  
  ;; ここからnow-open-shelf-with-fail-detection
  ;; ここからopen-shelf-set
  ;; 中間姿勢になる
  (move-arm-rarm-ik (make-coords :pos (float-vector 570 8500 31100) :rpy (float-vector 3.14 0.0 0.0)) 4000)
  
  ;; グリッパを微妙に開く
  (move-gripper-rarm 0.05)
  
  ;; 棚のノブの位置に腕を移動させる
  (send *arrow* :newcoords (send (car (send *shelf-door* :handle)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 100 0 -100) :world)
  (move-arm-rarm-ik (send *arrow* :copy-worldcoords) 4000)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (move-arm-rarm-ik (send *arrow* :copy-worldcoords) 4000)
  
  ;; 力覚を使ってノブの位置に手を移動させる．
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
  (touch-object-rarm-seq-x avs seq -15)
  
  
  ;; 少し腕を動かす
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(10 0 0) :world)
  (move-arm-rarm-ik (send *arrow* :copy-worldcoords) 1000)
  
  
  ;; 取手を掴む
  (grasp-object-rarm :gain 0.08)
  
  ;; ここに失敗検知を入れている!!! とりあえず保留？ smachを使うのが良いか？
  
  
  ;; ここからopen-shelf
  ;; 扉を開ける動作   ;; (move-object) ;; or (open-door)?
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
    (move-arm-seq avs tms)
    )
  ;; ここまでがopen-shelf
  
  ;; ここからafter-open
  (release-object-rarm)
  
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 20 -80) :world)
  (move-arm-rarm-ik (send *arrow* :copy-worldcoords) 3000)

  (send *arrow* :translate #f(0 -100 -100) :world)
  (move-arm-rarm-ik (send *arrow* :copy-worldcoords) 3000)
  ;; ここまでがafter-open
  ;; ここまでがnow-open-shelf-with-fail-detection  
  )


(defun curry-0-1-2-set-spatula ()  ;; ヘラをセットする
  
  ;; 下を見る set-head
  (move-head-set-angle 50 0.0 2000)
  
  ;;　receive-spatula-with-dialogue
  (move-arm-rarm-ik (make-coords :pos (float-vector 570 8500 31100) :rpy (float-vector 3.14 0.0 0.0)) 4000)
  
  
  ;; look-at-shelf
  
  
  ;; put-spatula-0
  
  
  
  )

(defun curry-0-1-3-set-ladle () ;; おたまをセットする

  )


(defun curry-0-1-4-close-shelf () ;; 棚の扉を閉める


  )