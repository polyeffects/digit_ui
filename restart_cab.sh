#!/bin/bash
if pgrep -xf "jconvolver /tmp cab.conf" >/dev/null
then
    PID=`pidof jconvolver`
    kill -s int $PID
    while kill -0 $PID; do
        sleep 0.1
    done
    nohup jconvolver /tmp/cab.conf >/dev/null 2>&1 &
else
    nohup jconvolver /tmp/cab.conf >/dev/null 2>&1 &
fi
# jack_connect jconvolver:OutL "postreverb:In Left"
# jack_connect jconvolver:OutR "postreverb:In Right"
# jack_connect reverb:Out jconvolver:In
