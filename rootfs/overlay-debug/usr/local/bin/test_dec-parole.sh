#!/bin/sh
#export GST_DEBUG=*:5
#export GST_DEBUG_FILE=/tmp/2.txt
su linaro -c "DISPLAY=:0.0 parole -i /usr/local/test.mp4"
