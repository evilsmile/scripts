local function print_tbl(tbl) 
    local str=''
    for k, v in pairs(tbl) do
        str = str .. ' ' .. k .. ':' .. v .. ' '
    end
end

local res = redis.call('SET', 'weight_info', 'a:4:0:4,b:2:0:2,c:1:0:1')

if not res or res['ok'] ~= "OK" then
    return 'reset failed'
else
    return 'reset succ'
end
