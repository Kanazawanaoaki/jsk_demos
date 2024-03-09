# jsk_2023_09_cook_from_recipe/scripts

レシピからの調理デモのscripts

### 自然言語のレシピからの実行可能な手順計画
自然言語のレシピ→関数　LLM
```
python convert_recipes_with_gpt4.py -k [OpenAI API Key] -r ../recipes/new_recipes/sauteed-broccoli.txt
```
関数→PDDLの定義　ルールベース処理
```
python convert_funcs_to_pddl_desc.py -i ../recipes/output_seqs/prompt_sunny-side-up.txt
```

PDDLの定義→補完されたプラン　PDDL  
```
roslaunch jsk_2023_09_cook_from_recipe only_planner.launch
roscd jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/
roseus solve-read-file-dish.l
(read-file "prompt_poached-egg_conv.l")
```