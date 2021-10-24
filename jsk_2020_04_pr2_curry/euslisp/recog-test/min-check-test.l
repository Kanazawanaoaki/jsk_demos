(defun min-check (data min) ;; 認識結果dataがminより上か下か一致しているか返す
  ;; (if (string-trim "/" *data*)
  ;;     )
  
  (setq hoge (string-trim "m" (string-trim "/" data)))
  (setq hoge (substringp "m" data))
  (setq hoge (and (substringp "m" hoge) (substringp "s" hoge)))
  (format t "debug data : ~A ~%" hoge)
  )

(warn "please run (min-check data 2) ~%")
