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

    # prompt_list = ["水が沸騰する", "バターが溶ける", "牛乳と卵がうまく混ざる", "卵に火が通る", "白身が固まる"]
    # prompt_list = ["水が沸騰する", "バターが溶ける", "牛乳と卵がうまく混ざる", "卵に火が通る", "卵の白身が固まる"]
    # prompt_list = ["沸騰した水", "液体のバター", "混ざっている牛乳と卵", "固体になった卵", "固まった卵の白身"]

    ###これを使っていた
    # prompt_list = ["水が沸騰する", "バターが溶ける", "牛乳と卵がうまく混ざる", "卵に火が通って固体になる", "卵に火が通る"]

    prompt_list = ["バターが溶ける", "バターが溶けて液体になる", "バターが液体になる"]

    words_list = []

    for t_prompt in prompt_list:
        print(t_prompt)
        ## translate to english
        translator = Translator()
        ans = translator.translate(t_prompt, dest='en')
        # print(ans)
        print(ans.text)
        verb_words = ans.text

        # prompt = 'Please put the negation of "{}"'.format(pos_words)
        # prompt = 'Please put the exact opposite of "{}"'.format(pos_words)
        # prompt = 'Please list some possible antonyms for "{}"'.format(pos_words)
        # prompt = 'Please list some possible negation of "{}"'.format(pos_words)
        # prompt = 'Please give me some candidates for the negation of "{}"'.format(pos_words)
        # prompt = '\nPlease list some possible negation of \"{}\"\n'.format(pos_words)

        # prompt = 'The noun version of "The room is clean." is "Clean room"\.\nThe noun version of "The laundry dries." is "Dried laundry"\.\nWhat is the noun version of "{}"?'.format(verb_words)
        # prompt = 'The noun version of The room is clean. is Clean room.\nThe noun version of The laundry dries. is Dried laundry.\nWhat is the noun version of {}?'.format(verb_words)
        prompt = 'The room is clean:Clean room\nThe laundry dries:Dried laundry\n{}:'.format(verb_words)
        print(prompt)

        response = openai.Completion.create(engine=model,
                                            prompt=prompt,
                                            temperature=temperature,
                                            echo=echo)
        # print(response)
        print(response['choices'][0]["text"])
        noun_words = response['choices'][0]["text"].strip().strip(".")
        # import ipdb
        # ipdb.set_trace()

        # words_list.append([verb_words, noun_words])

        prompt = 'Please list some possible antonyms for "{}"'.format(noun_words)
        print(prompt)

        response = openai.Completion.create(engine=model,
                                            prompt=prompt,
                                            temperature=temperature,
                                            echo=echo)
        # print(response)
        print(response['choices'][0]["text"])
        neg_words = response['choices'][0]["text"].strip().strip(".")

        words_list.append([verb_words, noun_words, neg_words])

    print(words_list)

    for words in words_list:
        pos_word = words[1]
        neg_word_list = words[2].split(",")
        # print(pos_word)
        # print(neg_word_list)
        tmp_prompt_list = []
        for neg_word in neg_word_list:
            if neg_word.strip() != "":
                # print(neg_word.strip())
                tmp_prompt_list.append([pos_word, neg_word.strip()])
        print(tmp_prompt_list)
