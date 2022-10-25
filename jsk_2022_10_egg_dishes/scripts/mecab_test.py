#! /usr/bin/python3
# -*- coding: utf-8 -*-

import MeCab
import argparse


if __name__ == "__main__":
    t = MeCab.Tagger()

    parser = argparse.ArgumentParser()
    parser.add_argument('-f','--file', default="test.txt")

    args = parser.parse_args()
    file_name = args.file
    print("text file loaded from {}".format(file_name))

    f = open(file_name, 'r')
    for i, line in enumerate(f):
        sentence = line.rstrip('\n')
        print("line " + str(i) + " : " + sentence)
        n = t.parseToNode(sentence)
        while n:
            print(n.surface, "\t", n.feature)
            n = n.next
