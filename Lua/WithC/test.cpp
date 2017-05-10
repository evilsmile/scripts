/* lua 和 c/c++ 交互的围绕着栈进行。
 * c/c++ 通过压栈(push系列函数) 然后 setglobal 把变量传递到lua的全局变量中
 * 然后调用 luaL_loadbuffer 调用脚本。
 * 完成之后调用 getglobal 得到全局变量，通过to*系列函数得到结果
 */
#include <iostream>
#include <string>

#include <lua.hpp>

int main()
{
    std::string szLua_code =
        "r = string.gsub(c_Str, c_Mode, c_Tag) -- \n"
        "u = string.upper(r)"
        "x = {} "
        "x[1], x[2] = string.gsub(c.Str, c.Mode, c.Tag) "
        "x.u = string.upper(x[1])"
        ;

    // Lua的字符串模式
    std::string szMode = "(%w+)%s*=%s*(%w+)";
    // 要处理的字符串
    std::string szStr = "key1 = value1 key2 = value2";
    // 目标字符串模式
    std::string szTag = "<%1>%2</%1>";

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    // lua_pushstring把C字符串压入栈顶
    lua_pushstring(L, szMode.c_str());

    // lua_setglobal把栈顶的数据传到Lua环境中作为全局变量
    lua_setglobal(L, "c_Mode");

    lua_pushstring(L, szTag.c_str());
    lua_setglobal(L, "c_Tag");

    lua_pushstring(L, szStr.c_str());
    lua_setglobal(L, "c_Str");

    // Lua的table相关操作
    // 新建table并压入栈顶
    lua_newtable(L);   

    // key
    lua_pushstring(L, "Mode");
    // value
    lua_pushstring(L, szMode.c_str());
    // 由于上面两次压栈，现在table元素排在栈顶往下数第三的位置
    // 设置newtable[Mode] = szMode
    lua_settable(L, -3);

    // key
    lua_pushstring(L, "Tag");
    // value
    lua_pushstring(L, szTag.c_str());
    // 设置newtable[Tag] = szTag
    lua_settable(L, -3);

    // key
    lua_pushstring(L, "Str");
    // value
    lua_pushstring(L, szStr.c_str());
    // 设置newtable[Str] = szStr
    lua_settable(L, -3);

    // 将栈顶元素(newtable)置为Lua中的全局变量c
    lua_setglobal(L, "c");

    bool err = luaL_loadbuffer(L, szLua_code.c_str(), szLua_code.size(), "demo") || lua_pcall(L, 0, 0, 0);

    if (err) 
    {
        std::cerr << lua_tostring(L, -1) << std::endl;
        lua_pop(L, 1);
    }
    else 
    {
        // 使用lua_getglobal从Lua环境中取得全局变量压入栈顶
        lua_getglobal(L, "r");
        // 然后使用lua_tostring把栈顶的数据转换成字符串。由于lua_tostring本身没有出栈功能，所以为了平衡(即调用前与调用后栈里的数据量不变),使用lua_pop弹出由lua_setglobal压入的数据
        std::cout << "r = " << lua_tostring(L, -1) << std::endl;
        lua_pop(L, 1);

        lua_getglobal(L, "u");
        if (lua_isstring(L, -1)) {
            std::cout << "u = " << lua_tostring(L, -1) << std::endl;
        }
        lua_pop(L, 1);

        lua_getglobal(L, "x");
        if (lua_istable(L, -1)) 
        {
            lua_pushstring(L, "u");
            lua_gettable(L, -2);

            std::cout << "x.u = " << lua_tostring(L, -1) << std::endl;
            lua_pop(L, 1);

            for(int i = 1; i <= 2; i++) 
            {
                lua_pushnumber(L, i);
                lua_gettable(L, -2);
                std::cout << "x[" << i << "]: " << lua_tostring(L, -1) << std::endl;
                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
    }

    lua_close(L);

    return 0;
}
