
# 为避免全局变量污染本应为局部变量的i, 通过形参来定义函数内部变量
# __ARGVEND__ 来表示真正的形参结束，后面是假形参,实际是局部变量
function factorial(n, __ARGVEND__, i, s)
{
    s = 1;
    for(i = 1; i <= n; i++) {
        s *= i;
    }

    return s;
}


