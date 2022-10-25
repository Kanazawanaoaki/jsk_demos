#! /usr/bin/python3
# -*- coding: utf-8 -*-

import os
import openai
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-k','--key', default="", help="受け取ったAPI key")
    parser.add_argument('-t','--temperature', default=0.0, type=float)
    parser.add_argument('-e','--echo', action='store_true')
    parser.add_argument('-p','--prompt', default="My favorite monster in Dragon Quest is")
    args = parser.parse_args()
    API_KEY = args.key
    temperature = args.temperature
    echo = args.echo
    prompt = args.prompt
    # API_KEY = "受け取ったAPI key"
    openai.api_key = API_KEY

    # prompt = "My favorite monster in Dragon Quest is"

    # response = openai.Completion.create(engine="davinci",
    #                                     prompt=prompt,
    #                                     temperature=temperature,
    #                                     echo=echo)
    response = openai.Completion.create(engine="text-davinci-002",
                                        prompt=prompt,
                                        temperature=temperature,
                                        echo=echo)
    print(response)
    print(response['choices'][0]["text"])
    # import ipdb
    # ipdb.set_trace()

