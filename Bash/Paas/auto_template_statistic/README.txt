/******************************************************
 * 此脚本目录文件的编写基于黑白模板的命中统计需求。   *
 ******************************************************

1. 文件列表：

	# 该目录存放所有来自于分布的access上传的过滤处理后的日志文件
	template_files_from_remote/
	
	# 分布的access需要执行的脚本，用于生成过滤后的日志文件，并上传到处理中心
	filter_access_log.sh  
	
	# 文件传输的expect脚本
	scp_tempfiles.expect  
	
	# 处理中心的统计脚本
	statis_template_hit_info.sh  
	
	# 工具函数脚本
	util.sh

2. 部署：
	分布的access: filter_access_log.sh、scp_tempfiles.expect util.sh
	处理中心: statis_template_hit_info.sh、util.sh、template_files_from_remote/(此目录需要预创建,不然access上传文件失败)
