# 行首是name，就读取下一行出来并打印
$1=="name"{print $0; getline; print $0;}
# 行首是age，直接打印
$1=="age"{print $0}
