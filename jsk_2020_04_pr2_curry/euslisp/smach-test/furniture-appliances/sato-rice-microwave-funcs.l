(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")

(defun recognition ()
  (unix:sleep 1)
  (warn "電子レンジの認識 ~%")
  )

(defun open-microwave ()
  (unix:sleep 1)
  (warn "電子レンジの扉を開ける ~%")
  )

(defun put-object () ;; サトウのご飯
  (unix:sleep 1)
  (warn "電子レンジに物体を入れる ~%")
  )

(defun close-microwave ()
  (unix:sleep 1)
  (warn "電子レンジの扉を閉める ~%")
  )

(defun push-500w-button ()
  (unix:sleep 1)
  (warn "500wのボタンを押す ~%")
  )

(defun push-1min-button-1 ()
  (unix:sleep 1)
  (warn "1minのボタンを押して1分にする ~%")
  )

(defun push-1min-button-2 ()
  (unix:sleep 1)
  (warn "1minのボタンを押して2分にする ~%")
  )

(defun push-start-button ()
  (unix:sleep 1)
  (warn "スタートボタンを押して温めを開始する ~%")
  )

(defun wait-2min ()
  (unix:sleep 1)
  (warn "2分間待つ ~%")
  )

(defun open-microwave-2 ()
  (unix:sleep 1)
  (warn "電子レンジの扉を開ける ~%")
  )

