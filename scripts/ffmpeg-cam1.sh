#!/bin/bash

CAMNUM=1
AUDIO_DELAY=0.24

# common parameters
. /usr/local/bin/ffmpeg-cam-common.sh

# to be launched once ffmpeg has started-ish.
(
   sleep 2
   echo "SETTING UP V4L2 for $VIDEO_DEV"
   v4l2-ctl -d ${VIDEO_DEV} -c saturation=0,power_line_frequency=1,exposure_dynamic_framerate=0,led1_mode=0,focus_automatic_continuous=0
   v4l2-ctl -d ${VIDEO_DEV} -c focus_absolute=135
   v4l2-ctl -d ${VIDEO_DEV} -c auto_exposure=1
   v4l2-ctl -d ${VIDEO_DEV} -c exposure_time_absolute=600
) &


start_stream
