#!/usr/bin/python

import sys
import getopt
from binascii import a2b_hex

def Usage():
    print 'Usage:'
    print '-h, --help: print help message'
    print '-d, --data: data to be written'
    print '-o, --output: file to write to'


def write_binary(data, file):
    if len(file) == 0 or len(data) == 0:
        Usage()
        return
    bin_data=a2b_hex(data)
    f = open(file, "wb")
    f.write(bin_data)
    f.close()

def main(argv):
    try:
        opts, args = getopt.getopt(argv[1:], 'hd:o:', [])
    except getopt.GetoptError, err:
        print str(err)
        Usage()
        sys.exit(1)

    data = ''
    file = ''
    for o, a in opts:
        if o in ('-h', '--help'):
            Usage()
            sys.exit(2)
        elif o in ('-d', '--data'):
            data = a
        elif o in ('-o', '--output'):
            file = a
        else:
            print 'unhandled option'
            sys.exit(3)
    write_binary(data, file)

if __name__ == '__main__':
    main(sys.argv)
