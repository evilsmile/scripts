#!/bin/bash

redis-cli --eval test_mutex.lua timer_task_lock:78a88bc989 , timer_send_comp_id
