#!/bin/bash
#make-run.sh
#make sure a process is always running.

process="greenctld"
makerun="./gasctld/greenctld --az-device /dev/azimuth --el-device /dev/elevation"


#echo "$process"
if ps ax | grep -v grep | grep $process > /dev/null
then
    echo `date +"%Y-%M-%d %T"`" - Nominal" >> gasctld/gasctld-log.txt
    exit
else
    $makerun &
    echo `date +"%Y-%M-%d %T"`" - Restarted" >> gasctld/gasctld-log.txt
fi

exit
