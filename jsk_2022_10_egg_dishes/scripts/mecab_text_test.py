#! /usr/bin/python3
# -*- coding: utf-8 -*-

import MeCab
import argparse


if __name__ == "__main__":
    tagger = MeCab.Tagger()

    parser = argparse.ArgumentParser()
    parser.add_argument('-t','--text', default="水が沸騰したら卵を鍋に入れる．")
    args = parser.parse_args()
    line = args.text

    sentence = line.rstrip('\n')
    print("text : " + sentence)
    n = tagger.parseToNode(sentence)
    s_list = []
    f_list = []
    while n:
        now_surface = n.surface
        now_feature = n.feature
        s_list.append(now_surface)
        f_list.append(now_feature)
        print(now_surface, "\t", now_feature)
        # print(n.surface, "\t", n.feature)
        n = n.next

    print(s_list)
    # for s,n in zip(s_list, f_list):
    #     print(s, n)
    # import ipdb
    # ipdb.set_trace()
