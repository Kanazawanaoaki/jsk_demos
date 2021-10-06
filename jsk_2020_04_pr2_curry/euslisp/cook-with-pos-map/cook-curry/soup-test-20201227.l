(warn "please run (soup-0) ~%")

;; 最初は鍋とカップが置いてある状態

;; 最初の準備
(defun soup-0 () 
  ;; ボウルと計量カップを置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (now-set-mcup)
  (now-set-4-model)
  
  (warn "please run (soup-1) ~%")
  )

;; ;; スープの元を皿に入れる
;; (defun soup-1 () 
;;   ;; ボウル４の中身を皿に入れる．
;;   (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
;;   (update-pos)
;;   (now-set-mcup)
;;   (now-set-4-model)
  
;;   (warn "please run (soup-1) ~%")
;;   )

;; 水を汲む
(defun soup-1 ()
  ;; 計量カップを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (now-grasp-mcup)
  
  ;; 水を汲んで注ぐ
  (setq pour-times 4)
  (dotimes (i pour-times)
    ;; sinkまで移動する
    (move-to-sink-ri)
    
    ;; 水を汲む
    (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
    (update-pos)
    (now-fetch-water)
    
    ;; 盛り付け位置まで移動する
    (go-to-arrange-from-sink)
    
    ;; 水を注ぐ
    (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
    (update-pos)
    (now-pour-water)
    )

  (warn "please run (soup-2) ~%")
  )

;; 沸騰させる
(defun soup-2 () 
  ;; コンロ操作をする 電源を入れるところから?
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  ;; (now-on-stove)
  (now-start-ih :deg 0) ;; 強火のまま？
  
  ;; 沸騰するまで見る等をする？ 音声対話を入れる？ ih-use-codesに入れておく？
  (look-at-pot)
  (dotimes (i 10)
    (unix:sleep 30)
    (send *ri* :speak-jp "画像を記録します")
    (unix:sleep 2)
    (rossrv-test)
    (send *ri* :speak-jp "記録しました")
    )

  ;; ;; コンロを止める
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  ;; (update-pos)
  ;; (push-knob)
  
  (warn "please run (soup-3) ~%")
  )


;; お湯をコップに注ぐ
(defun soup-3 ()
  
  (warn "玉ねぎをセットして　please run (curry-4) ~%")
  )
