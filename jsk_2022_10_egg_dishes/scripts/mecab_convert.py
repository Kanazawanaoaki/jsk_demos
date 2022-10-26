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
        if now_surface != "":
            s_list.append(now_surface)
            f_list.append(now_feature.split(","))
        print(now_surface, "\t", now_feature)
        # print(n.surface, "\t", n.feature)
        n = n.next

    # print(s_list)
    # print(f_list)
    cond_flag = False
    if 'たら' in s_list:
        cond_flag = True
        cond_word = 'たら'
    elif 'まで' in s_list:
        cond_flag = True
        cond_word = 'まで'

    if cond_flag:
        cond_index = s_list.index(cond_word)
        # print(cond_index)
        cond_text = ''
        for i, s in enumerate(s_list[:cond_index]):
            # print(f_list[i][0])
            # print(f_list[i][0] == "動詞")
            if f_list[i][0] == "動詞":
                cond_text += f_list[i][10]
            else:
                cond_text += s
        action_text = ''
        for s in s_list[cond_index+1:]:
            action_text += s

        if cond_word == 'たら':
            print(cond_text + " then do " + action_text)
        elif cond_word == 'まで':
            print("do " + action_text + " until " + cond_text)
    # import ipdb
    # ipdb.set_trace()
