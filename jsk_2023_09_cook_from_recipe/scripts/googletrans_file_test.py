#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from googletrans import Translator


if __name__ == "__main__":
    translator = Translator()

    parser = argparse.ArgumentParser()
    parser.add_argument('-f','--file', default="test.txt")

    args = parser.parse_args()
    file_name = args.file
    print("text file loaded from {}".format(file_name))
    ans_text_list = []

    f = open(file_name, 'r')
    for i, line in enumerate(f):
        sentence = line.rstrip('\n')
        print("line " + str(i) + " : " + sentence)
        # n = t.parseToNode(sentence)
        # while n:
        #     print(n.surface, "\t", n.feature)
        #     n = n.next

        # query_text = args.text
        query_text = sentence

        # ans = translator.translate('안녕하세요.', dest='ja')
        # ans = translator.translate('水が沸騰している', dest='en')
        # ans = translator.translate('沸騰している水', dest='en')

        ans = translator.translate(query_text, dest='en')
        print(ans)
        print(ans.text)
        ans_text_list.append(ans.text)

    print("[Translation Results]")
    for text in ans_text_list:
        print(text)
