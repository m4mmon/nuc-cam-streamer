#!/bin/bash

# trigger errors
set -e

if [ -z "$CAMNUM" ]
then
   echo "ERROR: CAMNUM not defined, cannot continue."
   return 1
fi

# necessary for running headless
export LIBVA_DRIVER_NAME=iHD
export LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri
export XDG_RUNTIME_DIR=/run/user/1000

# ---------------------------------------------------------------
#  override possible, those won't be evaluated in start_stream()
# ---------------------------------------------------------------

VIDEO_DEV=/dev/cam${CAMNUM}

# audio device
AUDIO_PW=alsa_input.usb-SmartlinkTechnology_Neewer_VM15_202309130000001-00.mono-fallback
AUDIO_DELAY=0
CAMNAME=CAM${CAMNUM}

# video definition
FPS=25
VIDSIZE=1920x1080

# delay
SRTLATENCY=50

# OSD

OSD_FONT_FILE="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
OSD_FONT_SIZE=50
OSD_FONT_BORDER_W=2
OSD_FONT_COLOR="white"
OSD_FONT_BORDER_COLOR="black"

OSD_LEFT=30
OSD_RIGHT=w-tw-30
OSD_TOP=30
OSD_BOTTOM=h-th-40

# default
OSD_CAM_POS_X=${OSD_LEFT}
OSD_CAM_POS_Y=${OSD_TOP}

OSD_TIME_POS_X=${OSD_RIGHT}
OSD_TIME_POS_Y=${OSD_BOTTOM}

OSD_DT_NAME_CAM="drawtext_cam"
OSD_DT_NAME_TIME="drawtext_time"

start_stream()
{
   SRT_PORT_BASE=9000
   ZMQ_PORT_BASE=19000

   SRT_PORT=$((SRT_PORT_BASE + CAMNUM))
   ZMQ_PORT=$((ZMQ_PORT_BASE + CAMNUM))

   # resolve OSD if some variables were overriden
   OSD_FONT="fontfile=${OSD_FONT_FILE}:fontsize=${OSD_FONT_SIZE}:fontcolor=${OSD_FONT_COLOR}:borderw=${OSD_FONT_BORDER_W}:bordercolor=${OSD_FONT_BORDER_COLOR}"
   OSD_CAM="drawtext@${OSD_DT_NAME_CAM}=${OSD_FONT}:x=${OSD_CAM_POS_X}:y=${OSD_CAM_POS_Y}:text='${CAMNAME}'"
   OSD_TIME="drawtext@${OSD_DT_NAME_TIME}=${OSD_FONT}:x=${OSD_TIME_POS_X}:y=${OSD_TIME_POS_Y}:text='%{localtime}'"
   #OSD_TIME="drawtext@${OSD_DT_NAME_TIME}=${OSD_FONT}:x=${OSD_TIME_POS_X}:y=${OSD_TIME_POS_Y}:text='%{localtime\:%H\\\\\\:%M\\\\\\:%S.%3N}'"

   exec /usr/bin/ffmpeg \
     -init_hw_device vaapi=va:/dev/dri/renderD128 \
     -init_hw_device qsv=qs@va \
     -hwaccel qsv \
     -hwaccel_output_format qsv \
     -filter_hw_device qs \
     -f v4l2 -input_format mjpeg -video_size $VIDSIZE -framerate $FPS \
     -use_wallclock_as_timestamps 1 \
     -i ${VIDEO_DEV} \
     -itsoffset ${AUDIO_DELAY} \
     -f pulse -i ${AUDIO_PW} \
     -fps_mode cfr \
     -vf "hwdownload,format=nv12,fps=${FPS},zmq=bind_address='tcp\://127.0.0.1\:${ZMQ_PORT}',${OSD_CAM},${OSD_TIME},hwupload=extra_hw_frames=64" \
     -c:v h264_qsv -b:v 4000k -g $FPS -bf 0 \
     -c:a aac -b:a 128k \
     -flush_packets 1 \
     -r $FPS \
     -f mpegts -muxdelay 0.1 -mpegts_flags initial_discontinuity "srt://0.0.0.0:${SRT_PORT}?mode=listener&pkt_size=1316&latency=${SRTLATENCY}"
}

start_stream_video_only()
{
   SRT_PORT_BASE=9000
   ZMQ_PORT_BASE=19000

   SRT_PORT=$((SRT_PORT_BASE + CAMNUM))
   ZMQ_PORT=$((ZMQ_PORT_BASE + CAMNUM))

   # resolve OSD if some variables were overriden
   OSD_FONT="fontfile=${OSD_FONT_FILE}:fontsize=${OSD_FONT_SIZE}:fontcolor=${OSD_FONT_COLOR}:borderw=${OSD_FONT_BORDER_W}:bordercolor=${OSD_FONT_BORDER_COLOR}"
   OSD_CAM="drawtext@${OSD_DT_NAME_CAM}=${OSD_FONT}:x=${OSD_CAM_POS_X}:y=${OSD_CAM_POS_Y}:text='${CAMNAME}'"
   OSD_TIME="drawtext@${OSD_DT_NAME_TIME}=${OSD_FONT}:x=${OSD_TIME_POS_X}:y=${OSD_TIME_POS_Y}:text='%{localtime}'"
   #OSD_TIME="drawtext@${OSD_DT_NAME_TIME}=${OSD_FONT}:x=${OSD_TIME_POS_X}:y=${OSD_TIME_POS_Y}:text='%{localtime\:%H\\\\\\:%M\\\\\\:%S.%3N}'"

   exec /usr/bin/ffmpeg \
     -init_hw_device vaapi=va:/dev/dri/renderD128 \
     -init_hw_device qsv=qs@va \
     -hwaccel qsv \
     -hwaccel_output_format qsv \
     -filter_hw_device qs \
     -f v4l2 -input_format mjpeg -video_size $VIDSIZE -framerate $FPS \
     -use_wallclock_as_timestamps 1 \
     -i ${VIDEO_DEV} \
     -fps_mode cfr \
     -vf "hwdownload,format=nv12,fps=${FPS},zmq=bind_address='tcp\://127.0.0.1\:${ZMQ_PORT}',${OSD_CAM},${OSD_TIME},hwupload=extra_hw_frames=64" \
     -c:v h264_qsv -b:v 4000k -g $FPS -bf 0 \
     -an \
     -flush_packets 1 \
     -r $FPS \
     -f mpegts -muxdelay 0.1 -mpegts_flags initial_discontinuity "srt://0.0.0.0:${SRT_PORT}?mode=listener&pkt_size=1316&latency=${SRTLATENCY}"
}
