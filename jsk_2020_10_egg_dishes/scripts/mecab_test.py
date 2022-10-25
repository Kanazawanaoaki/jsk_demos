#! /usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import MeCab


if __name__ == "__main__":
    t = MeCab.Tagger()
    file_name = "test.txt"
    if len(sys.argv)>=2:
        file_name = sys.argv[1]

    f = open(file_name, 'r')
    for i, line in enumerate(f):
        sentence = line.rstrip('\n')
        print("line " + str(i) + " : " + sentence)
        n = t.parseToNode(sentence)
        while n:
            print(n.surface, "\t", n.feature)
            n = n.next
