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
    parser.add_argument('-j','--japanese', default="沸騰している水")
    parser.add_argument('-p','--positive', default="")
    parser.add_argument('-m','--model', default="text-davinci-002")
    args = parser.parse_args()
    API_KEY = args.key
    temperature = args.temperature
    echo = args.echo
    j_prompt = args.japanese
    model = args.model
    # API_KEY = "受け取ったAPI key"
    openai.api_key = API_KEY

    ## translate to english
    translator = Translator()
    ans = translator.translate(j_prompt, dest='en')
    print(ans)
    print(ans.text)
    pos_words = ans.text

    if args.positive != "":
        pos_words = args.positive

    prompt = 'Please put the negation of "{}"'.format(pos_words)
    print(prompt)

    response = openai.Completion.create(engine=model,
                                        prompt=prompt,
                                        temperature=temperature,
                                        echo=echo)
    print(response)
    print(response['choices'][0]["text"])
    neg_words = response['choices'][0]["text"].strip().strip(".")
    # import ipdb
    # ipdb.set_trace()
    print("positive word is :{}".format(pos_words))
    print("negative word is :{}".format(neg_words))
