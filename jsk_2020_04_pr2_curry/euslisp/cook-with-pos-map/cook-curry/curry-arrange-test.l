(warn "please run (curry-a-0) ~%")

(defun curry-a-0 () ;;最初に準備をする
  
  
  )

(defun curry-a-1 ()
  ;; 電子レンジまで移動する　(それか棚の前まで移動してサトウのご飯を掴む動作をするなど，それには認識が必要か？)
  ;; TODO

  
  ;; サトウのごはんを調理する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/microwave-codes.l")
  (update-pos)
  (now-sato-rice-micro) ;; TODO用意する
   
  ;; サトウのごはんを持ってキッチンまで行く (移動先で受け取る？持ったまま移動して左手に渡すか？) 
  ;; TODO
  
  (warn "please run (curry-a-2) ~%")
  )

(defun curry-a-2 ()
  ;; サトウのごはんを盛り付ける ;;TODO ヘラを 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (grasp-spatula)
  (now-arrange-sato)
  (put-spatula)
  
  ;; 少し温めるなら温める (今は良いかな？)
  
  
  ;; カレーを盛り付ける
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (grasp-ladle)
  (now-arrange-curry)
  (put-ladle)
  
  ;;完成！！
  
  )

