#!/bin/bash
cd /home/m_ren/qwen3.5
./llama.cpp/llama-server \
  --model MODEL_FILE \
  --alias MODEL_ALIAS \
  --port 8001 \
  --ctx-size 32768 \
  --n-gpu-layers 999 \
  --temp TEMP_VALUE \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.00 \
  --repeat-penalty 1.0 \
  --presence-penalty PRESENCE_VALUE \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --flash-attn on \
  --batch-size 2048 \
  --ubatch-size 512 \
  --parallel 2 \
  --cont-batching \
  --jinja \
  --chat-template-kwargs '{"enable_thinking":true}'