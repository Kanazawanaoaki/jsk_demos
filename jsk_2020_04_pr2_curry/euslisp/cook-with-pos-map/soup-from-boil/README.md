# soup-from-boil
スープを作るデモの移動無しver. 

TODO 画像を貼る

## 準備
google スライドに従いながらハードウェア等の準備をする．

```
roscd jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/soup-from-boil
roseus move-to-kitchen-with-map.l
(move-to-arrange-ri-direct)
```
としてPR2を位置に移動させる．移動が失敗した場合はps3joyでアシストする．

## 実行
```
roscd jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/soup-from-boil
roseus soup-arrange-test-20211008.l
(soup-arrange-all)
```
でプログラムを実行する．


### デモの内容
``
(defun soup-arrange-all ()
  (soup-arrange-0) ;; 最初の準備
  (unix:sleep 2)
  (soup-arrange-1) ;; 沸騰させる
  (unix:sleep 2)
  (soup-arrange-2) ;; お湯を注ぐ
  ;; (unix:sleep 2)
  ;; (soup-arrange-3) ;; 冷ます
  )
```

#### 最初の準備
PR2の音声に従いながらおたまとお皿をセットする．