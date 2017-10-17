#!/bin/env python

#coding=utf-8
import urllib
import re

MAX_SEARCH_LVL=1

init_url="http://www.sina.com.cn"

def getHtml(url):
    page = urllib.urlopen(url)
    html = page.read()
    return html

def getHref(url, curlevel):
    if curlevel>MAX_SEARCH_LVL:
        return
    try:
        page = urllib.urlopen(url)
        html = page.read()
    except:
        print "error..."
        return

    reg = r'href="(http://[^/:"]+)[^ ]*"'
    hrefre = re.compile(reg)
    hreflist = set(re.findall(hrefre, html))
    for newurl in hreflist:
        print newurl
        getHref(newurl, curlevel+1)

def getImg(html):
    reg = r'href="(http://.+)"'
    imgre = re.compile(reg)
    imglist = re.findall(imgre, html)
    x = 0
    for imgurl in imglist:
        urllib.urlretrieve(imgurl,'%s.jpg' % x)
        x+=1
    
getHref(init_url, 0)
