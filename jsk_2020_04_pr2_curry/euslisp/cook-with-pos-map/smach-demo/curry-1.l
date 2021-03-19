;; 人参の下ごしらえのプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-1 () ;; 準備をする．  
  
  ;; 人参を掴む ;;pap
  (curry-1-1-grasp-carrot)
  
  ;; シンクの前に移動する ;;move
  (curry-1-2-move-to-sink)
  
  ;; 人参を洗う ;;特殊
  (curry-1-3-wash-carrot)
  
  ;; キッチンの前に戻る ;;move
  (curry-1-4-move-to-kitchen)
  
  ;; 人参をまな板に置く ;;pap
  (curry-1-5-put-carrot-on-board)
  
  ;; ピーラーを掴む ;;pap
  (curry-1-6-grasp-peeler)
  
  ;; 人参の皮剥き ;;特殊
  (curry-1-7-peel-carrot)
  
  ;; ピーラーを置く，包丁を掴む ;;pap
  (curry-1-8-replace-tool)
  
  ;; 人参切断 ;;特殊
  (curry-1-9-cut-carrot)

  ;; 包丁を置く ;;pap
  (curry-1-10-put-knife)
  
  ;; ボウル１に移す動作 ;;特殊
  (curry-1-11-transfer-to-bowl-1)  
  )


;; 人参を掴む ;;transition
(defun curry-1-1-grasp-carrot ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  ;; (update-pos)
  ;; (now-grasp-carrot-with-fail-detection)
  
  ;; このgraspをsmachでやってみる？

  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (before-receive-larm) ;; 中間姿勢になる
  (grasp-carrot-with-fail-detection) ;;失敗検知をしながら掴む
  (after-grasp-vegs) ;; 持ち上げる
  (vegs-carry-pose)   ;; 運ぶ姿勢になる  
  )

;; シンクの前に移動する ;;transition
(defun curry-1-2-move-to-sink ()
  (move-to-sink-with-speech-before) ;; primitive
  )

;; 人参を洗う
(defun curry-1-3-wash-carrot ()
  ;;; TODO 大事 野菜をせっと，水道操作，野菜を動かす　などの複数の手順が必要である．

  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  ;; (update-pos)
  ;; (now-wash-veg)
  
  )

;; キッチンの前に戻る ;;transition
(defun curry-1-4-move-to-kitchen ()
  (move-to-kitchen-with-speech-after) ;; primitive
  )

;; 人参をまな板に置く
(defun curry-1-5-put-carrot-on-board ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  ;; (update-pos)
  ;; (now-put-carrot-on-board)  
  )

;; ピーラーを掴む ;; transition
(defun curry-1-6-grasp-peeler ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  ;; (update-pos)
  ;; (grasp-peeler-with-fail-detection)
  )

;; 人参の皮剥き
(defun curry-1-7-peel-carrot ()
  ;;; TODO  重要 階層的になっている部分!!

  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-carrot-codes.l")
  ;; (update-pos)
  ;; (now-peel)
  ;; (now-rotate)
  ;; (now-peel)

  )

;; ピーラーを置く，包丁を掴む ;; transition
(defun curry-1-8-replace-tool ()
  ;; ピーラーを置く

  ;; 包丁を掴む
  
  
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  ;; (update-pos)
  ;; (put-peeler)
  ;; (grasp-knife-with-fail-detection)
  )

;; 人参切断
(defun curry-1-9-cut-carrot ()
  ;;; TODO 重要 力覚を使ったりなどしている．
  
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-carrot-codes.l")
  ;; (update-pos)
  ;; (now-cut)
  )

;; 包丁を置く ;;transtion
(defun curry-1-10-put-knife ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  ;; (update-pos)
  ;; (put-knife)
  ;; (reset-rarm)  
  )

;; ボウル１に移す動作
(defun curry-1-11-transfer-to-bowl-1 ()
  ;; 重要　複数手順がある
  
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  ;; (update-pos)
  ;; (now-cutting-board-transfer-bowl-1-all-with-fail-detection)

  )

