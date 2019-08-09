package models

import (
   "github.com/astaxie/beego/orm"
   "ForkBackend/utils"
   "github.com/astaxie/beego/logs"
    _ "github.com/go-sql-driver/mysql"
)

{{.Types}}

func init() {

   conf, err := utils.GetConfig()
   if err != nil {
       logs.Error("read config error: ", err)
       return
   }

   datasource := conf.String("mysql::datasource")
   if datasource == "" {
      datasource = "mysql:123456@tcp(127.0.0.1:3306)/test?charset=utf8"
      logs.Warning("mysql datasource not configured! Use default '%s'", datasource)
   }

    orm.RegisterDataBase("default", "mysql", datasource, 30)

	{{.Registers}}
}
