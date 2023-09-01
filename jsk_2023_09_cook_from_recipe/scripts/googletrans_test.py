#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from googletrans import Translator

translator = Translator()

parser = argparse.ArgumentParser()
parser.add_argument('-t','--text', default='沸騰している水')

args = parser.parse_args()
query_text = args.text

# ans = translator.translate('안녕하세요.', dest='ja')
# ans = translator.translate('水が沸騰している', dest='en')
# ans = translator.translate('沸騰している水', dest='en')

ans = translator.translate(query_text, dest='en')
print(ans)
print(ans.text)
