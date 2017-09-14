
local weight_config = redis.call('GET', 'weight_info')

local channelweight={}
-- channel_id:weight-curweight-effweight
--string.gsub("a:4:0:4,b:2:0:2,c:1:0:1", '[^,]+', function(channelinfo)
--分两次截取。 先截出','分隔的串，再对每个串按':'分隔，存入channelweight
string.gsub(weight_config, '[^,]+', function(channelinfo)

    -- 按':'分隔， 放入details_tmp
    local details_tmp={}
    string.gsub(channelinfo, '[^:]+', function(detail)
                    table.insert(details_tmp, detail) 
                end)

    -- 再依次取出按定义好的字段存入channelweight
    table.insert(channelweight, {
        channelid=details_tmp[1], 
        weight=tonumber(details_tmp[2]),
        curweight=tonumber(details_tmp[3]),
        effweight=tonumber(details_tmp[4])
    })

end)

local function cmps(a, b)
    return a.curweight > b.curweight
end

local total=0

for k, v in pairs(channelweight)
do
    v.curweight = v.curweight + v.effweight
    total = total + v.effweight
end

table.sort(channelweight, cmps)

channelweight[1].curweight = channelweight[1].curweight - total

local sorted_channels=''
local new_v=''
for k, v in pairs(channelweight)
do
    sorted_channels=sorted_channels..','..v.channelid
    new_v=new_v..','..v.channelid..':'..v.weight..':'..v.curweight..':'..v.effweight
--    print(v.channelid, v.curweight)
end

new_v = string.sub(new_v, 2)
sorted_channels = string.sub(sorted_channels, 2)

local res = redis.call('SET', 'weight_info', new_v)

return sorted_channels
