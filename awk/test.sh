#!/bin/bash

#awk -f test1.awk test1.data

# 包含函数文件来实现类似include的效果
echo "" | awk -f fac_call.awk -f fac_func.awk 
