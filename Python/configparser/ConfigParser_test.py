#!/bin/env python

import ConfigParser

cf = ConfigParser.ConfigParser()

cf.read("config.ini")

s = cf.sections()
# output "section: ['db', 'concurrent']"
print 'section:', s

v = cf.items("db")
print 'db:', v

db_host = cf.get("db", "db_host")
db_port = cf.getint("db", "db_port")

threads = cf.getint("concurrent", "thread")

print "db_host: ", db_host
print "db_port: ", db_port
print "threads: ", threads

####################################
config = ConfigParser.ConfigParser()
config.add_section("date")
config.set("date", "year", "2017")
config.write(open("out.ini", "w"))
