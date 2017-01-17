#!/bin/bash

exec 4<&0 0<stock.txt

read line1
read line2
exec 0<&4
echo $line1
echo $line2

