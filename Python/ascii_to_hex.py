#!/usr/bin/python

# -*- coding: utf-8 -*-

import binascii
import sys
from sys import argv

if __name__ == '__main__':

    if  len(argv) != 2:
        print "Usage: {0} hex_str".format(argv[0])
        sys.exit(1)

    print binascii.b2a_hex(argv[1])
