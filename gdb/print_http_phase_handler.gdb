file /usr/local/nginx/sbin/nginx

# 关闭 print时的"Type <Enter> to continue----" 的提示和等操作
set pagination off 

# Attach
attach 23073

# 断点1
# 此断点为循环点
b ngx_http_core_module.c:860
# 断点2
# 此断点为循环中断点
b ngx_http_core_module.c:863

# 为断点1设置命令集
commands 1
    # 不打印断点信息
	silent
	set $a=ph[r->phase_handler]
    print $a
	continue
end

# 为断点2设置命令集
commands 2 
	silent
	detach
	quit
end

# 设置好了，可以继续执行了
continue
