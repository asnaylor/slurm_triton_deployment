#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --constraint=gpu
#SBATCH --qos=regular
#SBATCH --account=evlis


NGC_VERSION=24.11
TRITON_IMAGE=nvcr.io/nvidia/tritonserver:${NGC_VERSION}-py3
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MODEL_DIR=$SCRIPT_DIR/model_repository

NGPUS_PER_NODE=4
CPUS_PER_TASK=32
CONTAINER_CMD="shifter --module=gpu --image=$TRITON_IMAGE"

export MODEL_DIR
export CONTAINER_CMD

set -x

srun \
    --ntasks-per-node=$NGPUS_PER_NODE \
    --gpus-per-task=1 --cpus-per-task=$CPUS_PER_TASK \
    --label --unbuffered \
    bash -c '$CONTAINER_CMD \
                tritonserver \
                    --model-repository=$MODEL_DIR \
                    --http-port $((8000 + $SLURM_LOCALID*10)) \
                    --grpc-port $((8001 + $SLURM_LOCALID*10)) \
                    --metrics-port $((8002 + $SLURM_LOCALID*10)) \
                    --log-verbose=3'