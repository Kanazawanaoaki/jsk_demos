#!/usr/bin/env python3

import re
import sys

import sounddevice as sd


def find_device_from_device_name(name, in_or_out='input'):
    devices = sd.query_devices()
    for d in devices:
        if d['name'].startswith(name):
            if in_or_out == 'input' and d['max_input_channels'] > 0:
                return d
            elif in_or_out == 'output' and d['max_output_channels'] > 0:
                return d
    return None


if __name__ == '__main__':
    try:
        device_name = sys.argv[1]
        in_or_out = sys.argv[2]
    except IndexError:
        print('plughw:0,0')
        sys.exit(0)
    device_info = find_device_from_device_name(device_name, in_or_out=in_or_out)

    try:
        found = re.search('\(hw:\d,\d\)', device_info['name']).group(0)
        print('plug' + found.strip('()'))
    except TypeError:
        print('plughw:0,0')
