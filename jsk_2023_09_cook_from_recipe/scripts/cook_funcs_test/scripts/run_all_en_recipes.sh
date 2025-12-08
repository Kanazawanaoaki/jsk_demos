#!/usr/bin/env bash

# 使い方チェック
if [ $# -lt 1 ]; then
  echo "Usage: $0 API_KEY"
  exit 1
fi

API_KEY="$1"

# このスクリプトを recipe_conv_test.py と同じディレクトリで実行する想定
# ../texts/en_recipes/ 以下のすべての .txt ファイルに対して実行
find ../texts/en_recipes -type f -name "*.txt" | while read -r txtfile; do
  echo "Processing: $txtfile"
  python recipe_conv_test.py -r "$txtfile" -k "$API_KEY"
done
