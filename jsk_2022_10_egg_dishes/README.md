# jsk_2020_10_egg_dishes

レシピからの卵料理デモ

## tmp scripts


### MeCab
```
python3 mecab_file_test.py -f ../recipes/omelette.txt
```
```
python3 mecab_text_test.py -t バターが溶けたら卵をフライパンに注ぐ．
```


### googletrans
```
python3 googletrans_test.py -t 水が沸騰する
```

### GPT-3
```
python3 gpt-3_test.py -k [YOUR API KEY] -t 0.0 -e -p 'Please put "The water boils" in a noun form ending in water.
'
```


### Make prompt
日本語の単語，あるいは英語の単語から(-p 引数)でも対の意味になるpromptを生成できる．
```
python3 make_prompt.py -k [YOUR API KEY] -j 液体になった卵
```

それを複数実行するパターン．
```
python3 test_make_prompt.py -k [YOUR API KEY]
```