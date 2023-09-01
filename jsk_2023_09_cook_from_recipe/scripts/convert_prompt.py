#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import openai
import argparse
from googletrans import Translator

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-k','--key', default="", help="受け取ったAPI key")
    parser.add_argument('-t','--temperature', default=0.0, type=float)
    parser.add_argument('-e','--echo', action='store_true')
    parser.add_argument('-p','--prompt', default="沸騰している水")
    parser.add_argument('-m','--model', default="text-davinci-002")
    args = parser.parse_args()
    API_KEY = args.key
    temperature = args.temperature
    echo = args.echo
    t_prompt = args.prompt
    model = args.model
    # API_KEY = "受け取ったAPI key"
    openai.api_key = API_KEY

    words_list = [['Boiled water', 'Frozen water, ice water, cold water, room temperature water,'], ['Liquid butter', 'Solid butter, margarine, oil, water'], ['Mixed milk and eggs', 'Separated milk and eggs'], ['Solid egg', 'Runny egg, liquid egg, broken egg, scrambled egg, po'], ['White of the hardened egg', 'yolk, runny, liquid, soft']]

    for words in words_list:
        pos_word = words[0]
        neg_word_list = words[1].split(",")
        # print(pos_word)
        # print(neg_word_list)
        tmp_prompt_list = []
        for neg_word in neg_word_list:
            if neg_word.strip() != "":
                # print(neg_word.strip())
                tmp_prompt_list.append([pos_word, neg_word.strip()])
        print(tmp_prompt_list)

        ## translate to english
    #     translator = Translator()
    #     ans = translator.translate(t_prompt, dest='en')
    #     print(ans)
    #     print(ans.text)
    #     pos_words = ans.text

    #     # prompt = 'Please put the negation of "{}"'.format(pos_words)
    #     # prompt = 'Please put the exact opposite of "{}"'.format(pos_words)
    #     prompt = 'Please list some possible antonyms for "{}"'.format(pos_words)
    #     print(prompt)

    #     response = openai.Completion.create(engine=model,
    #                                         prompt=prompt,
    #                                         temperature=temperature,
    #                                         echo=echo)
    #     print(response)
    #     print(response['choices'][0]["text"])
    #     neg_words = response['choices'][0]["text"].strip().strip(".")
    #     # import ipdb
    #     # ipdb.set_trace()

    #     words_list.append([pos_words, neg_words])

    # print(words_list)
