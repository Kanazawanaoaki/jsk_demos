# cook from recipe PDDL test

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