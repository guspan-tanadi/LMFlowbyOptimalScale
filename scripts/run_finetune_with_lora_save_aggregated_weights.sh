#!/bin/bash
# Please run this script under ${project_id} in project directory of

# Parses arguments
model_name_or_path=gpt2
dataset_path=data/alpaca/train
output_dir=output_models/finetune
deepspeed_args="--master_port=11000"

while [[ $# -ge 1 ]]; do
  key="$1"
  case ${key} in
    -h|--help)
      echo "${help_message}" 1>&2
      exit 0
      ;;
    -m|--model_name_or_path)
      model_name_or_path="$2"
      shift
      ;;
    -d|--dataset_path)
      dataset_path="$2"
      shift
      ;;
    -o|--output_model_path)
      output_dir="$2"
      shift
      ;;
    --deepspeed_args)
      deepspeed_args="$2"
      shift
      ;;
    *)
      echo "error: unknown option \"${key}\"" 1>&2
      exit 1
  esac
  shift
done

# Finetune
exp_id=finetune_with_lora
project_dir=$(cd "$(dirname $0)"/..; pwd)
log_dir=${project_dir}/log/${exp_id}
mkdir -p ${output_dir} ${log_dir}

deepspeed ${deepspeed_args} \
  examples/finetune.py \
    --model_name_or_path facebook/galactica-1.3b \
    --dataset_path ${dataset_path} \
    --output_dir ${output_dir} --overwrite_output_dir \
    --num_train_epochs 0.01 \
    --learning_rate 1e-4 \
    --block_size 512 \
    --per_device_train_batch_size 1 \
    --use_lora 1 \
    --lora_r 8 \
    --save_aggregated_lora 1\
    --deepspeed configs/ds_config_zero2.json \
    --fp16 \
    --run_name finetune_with_lora \
    --validation_split_percentage 0 \
    --logging_steps 20 \
    --do_train \
    --do_eval \
    --evaluation_strategy "steps" \
    --eval_steps 1000 \
    --eval_dataset_path ${eval_dataset_path} \
    --ddp_timeout 72000 \
    --save_steps 5000 \
    --dataloader_num_workers 1 \
    | tee ${log_dir}/train.log \
    2> ${log_dir}/train.err
