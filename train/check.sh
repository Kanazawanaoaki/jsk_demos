#!/bin/bash

echo $(docker ps -q --filter "name=$USER-train-pytorch-object-detection" | wc -l)
