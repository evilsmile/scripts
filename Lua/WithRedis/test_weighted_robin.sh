#!/bin/bash

TMPFILE=/tmp/weighted_robin_test_tmp.data

redis-cli --eval reset_weight.lua

>$TMPFILE
for i in {1..1000}; do
    redis-cli --eval weighted_robin.lua >> $TMPFILE
done

awk -F"," '{sum[$1]++;}END{for(s in sum) { print s, sum[s]}}' $TMPFILE
