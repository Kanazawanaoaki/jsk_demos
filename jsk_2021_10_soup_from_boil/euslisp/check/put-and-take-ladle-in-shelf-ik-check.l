(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/tool-at-arrange.l")
(load "package://jsk_2021_10_soup_from_boil/euslisp/util/move-to-kitchen-with-map.l")

;; IRT上でIKのチェックをする
(ros::roseus "shelf_ik_check" :anonymous t)
(move-on-irt :kitchen)

(warn "please run (check) ~%")

;; TODO random-coordsやmake-random-cds-list，checkも引数に関数（とpr2-spot-listも？）をとるようにしてチェックするようにする？ IKでも場所によって重要度とかがある？他のIKが大事な部分もこれで出来るようにする．

;; 今回はmove-rarm-to-ladle-at-shelfを少し変更して，IK失敗をカウントして返り値として返すようにして，:send-riの引数で*ri*に送るかどうかを指定できるようにして時短に．

(defun random-coords (initial-cds &key (x 100) (y 50) (theta 30))
  (let (ans-cds x-num y-num theta-num)
    (setq ans-cds (send initial-cds :copy-worldcoords))
    (setq x-num (random x))
    (if (= (random 2) 1)
        (setq x-num (* x-num -1)))
    (setq y-num (random y))
    (if (= (random 2) 1)
        (setq y-num (* y-num -1)))
    (setq theta-num (random theta))
    (if (= (random 2) 1)
        (setq theta-num (* theta-num -1)))
    (send ans-cds :translate (float-vector x-num y-num 0) :world)
    (send ans-cds :rotate (deg2rad theta-num) :z :world)
    ans-cds))

(defun make-random-cds-list (initial-cds &key (x 100) (y 50) (theta 30) (num 10)) ;; TODO？指定した範囲の境界部分，最大最初？とかは入るように最初にしてする？四隅とか回転はどうしようか．
  (let (ans-cds-list list)
    (dotimes (i num)
      (setq ans-cds-list (append ans-cds-list (list (random-coords initial-cds :x x :y y :theta theta))))
      )
    ans-cds-list))

(defun check ()
  (let (pr2-spot-list (all-ik-success t) (num-ik-fail 0) (num-ik-fail-spot 0) (result-list (list)))
    (setq pr2-spot-list (make-random-cds-list (make-coords :pos #f(1050 8500 30000) :rpy (float-vector pi 0 0)) :x 50 :y 50 :theta 10 :num 30)) ;; 前後左右50mm，回転±10degの範囲内でランダムに30箇所でチェック（今は範囲は適当）
    ;; (setq pr2-spot-list (list (make-coords :pos #f(1050 8500 30000) :rpy (float-vector pi 0 0)) (make-coords :pos (float-vector 1200 8200 30000) :rpy (float-vector pi 0 0)))) ;; listで直接spotを指定，現在棚を操作している位置？とarrange-spotの座標．
    (dolist (spot pr2-spot-list)
      (send *pr2* :move-to (send spot :copy-worldcoords) :world)
      (set-ladle);; move-rarm-to-ladle-at-shelfではladleが手にassocされていることが必要．
      (setq result (move-rarm-to-ladle-at-shelf :send-ri nil));; move-rarm-to-ladle-at-shelfをriに送らずに実行．
      (setq result-list (append result-list (list result)))
      (format t "~A ik fail at ~A ~%" result spot)
      )
    (warn "---- IK check result ----- ~%")
    (dotimes (i (length pr2-spot-list));; IK失敗時はログが出て埋もれるのでdolist内の個別spotの結果を全IK終了後にも描画．
      (format t "~A ik fail at ~A ~%" (elt result-list i) (elt pr2-spot-list i))
      (unless (= (elt result-list i) 0)
        (setq all-ik-success nil)
        (setq num-ik-fail (+ num-ik-fail (elt result-list i)))
        (setq num-ik-fail-spot (+ num-ik-fail-spot 1))
        )
      )
    (if all-ik-success
        (format t "(total) all ik success!! ~%")
      (format t "(total) ~A ik fail at ~A/~A spots ~%" num-ik-fail num-ik-fail-spot (length pr2-spot-list)))
    ))
