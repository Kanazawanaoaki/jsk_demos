#!/bin/bash

# download data
python data.py

docker build -f ./docker/Dockerfile \
       --rm \
       -t train-object-detection-from-images \
       .
