local lock_ret = redis.call('SETNX', KEYS[1], ARGV[1])
if lock_ret == 1 then 
    return {'succ', ARGV[1]}
else 
    local lock_holder = redis.call('GET', KEYS[1]) 
    return {'failed', lock_holder}
end 
