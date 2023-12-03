# cook from recipe PDDL test


## convert func
```
cd func-conv-test
python conv_test.py -i functions.txt
```

## pddl plan
launch
```
roslaunch only_planner.launch
```

euslisp
```
rlwrap roseus solve-read-file-dish.l
read-file "sunny-side-up.l"
```
You need to edit `solve-read-file-dish.l`'s variables and conditions.