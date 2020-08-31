#!/bin/bash

# TODO: is it an issue that these changes don't persist through a reboot?
for cpunum in $(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | cut -s -d, -f2- | tr ',' '\n' | sort -un)
do
    echo 0 > /sys/devices/system/cpu/cpu$cpunum/online
done
