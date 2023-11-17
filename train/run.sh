#!/bin/bash

function message() {
    local color=$1; shift;
    local message=$@

    # Output command being executed
    echo -e "\e[${color}m${message}\e[0m"
}

DATASET_DIR=$(realpath $1); shift 1;
DATASET_NAME=$(basename $DATASET_DIR)
if [ -z "${DATASET_DIR}" ]; then
    echo "[ERROR]: DATASET_DIR should be set."
    exit 1
fi
echo "Target Dir: ${DATASET_DIR}"

batchsize=16
epoch=10
outpath=$(realpath ./gen_data)
while getopts "b:e:o:" opt; do
    case $opt in
        b)
            batchsize=$OPTARG
            ;;
        e)
            epoch=$OPTARG
            ;;
        o)
            outpath=$(realpath $OPTARG)
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

echo "Batch size: $batchsize"
echo "Number of epochs: $epoch"

if [ -t 1 ]; then
    TTY_OPT='-ti'
else
    TTY_OPT=''
fi


cmd="python generate_data.py --from-images-dir /workspace/target_data -b ${batchsize} --epoch ${epoch} --compress-annotation-data --out /home/user${outpath} --pretrained-model-path /workspace/yolov8x-seg.pt"
docker run --rm \
       -u "$(id -u $USER):$(id -g $USER)" \
       --userns=host \
       --gpus all \
       --shm-size=1g \
       --name $USER-train-pytorch-object-detection \
       --env="DISPLAY" \
       --env="QT_X11_NO_MITSHM=1" \
       --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
       --volume="$HOME/.project_t:/home/user/.project_t:rw" \
       --volume="${DATASET_DIR}:/workspace/target_data:rw" \
       --volume="${outpath}:/home/user${outpath}:rw" \
       ${TTY_OPT} train-object-detection-from-images $cmd

message 32 "Done generating model file for pytorch object detection"
message 32 " - ${outpath}/train/weights/best.pt"
