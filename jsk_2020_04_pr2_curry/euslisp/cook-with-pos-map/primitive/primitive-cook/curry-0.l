# 準備のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

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
  
  ;; 棚の方を見る look-at-shelf
  (move-head)
  
  ;; ここからnow-open-shelf-with-fail-detection
  ;; ここからopen-shelf-set
  ;; 中間姿勢になる
  (move-arm)

  ;; グリッパを微妙に開く
  (move-gripper)

  ;; 棚のノブの位置に腕を移動させる
  (move-arm)

  ;; 力覚を使ってノブの位置に手を移動させる．
  (touch-object) ;; or (move-object)の力覚有り版？？

  ;; 少し腕を動かす
  (move-arm)

  ;; 取手を掴む
  (grasp-object)
  ;; ここまでがopen-shelf-set
  
  ;; ここに失敗検知を入れている!!!

  ;; ここからopen-shelf
  ;; 扉を開ける動作
  (move-object) ;; or (open-door)?
  ;; ここまでがopen-shelf

  ;; ここからafter-open
  (move-arm)
  ;; ここまでがafter-open
  ;; ここまでがnow-open-shelf-with-fail-detection

  ;; 下を見る set-head
  (move-head)
  
  ;;
  
  )
