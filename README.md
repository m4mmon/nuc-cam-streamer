Resources related to the streaming of USB cameras connected to a NUC computer running linux.

# per-camera setup

TODO

## udev rules

TODO

## service

TODO

## control script

TODO

# OBS

TODO

## source config

Use a "media source" for each camera.

Uncheck "local file".

Uncheck "start from the beginning".

Input: srt://<server>:<source port as defined in the script>

Input format: mpegts

Lower the delay if your network allows it.

Use hardware acceleration if possible.

# sources synchronization

TODO

## A/V

In case the audio and video are streamed simultaneously (mixed with ffmpeg), adjust the itsoffset value relative to the audio source. It must be done independently for each camera.

Even with the same camera models, I discovered I had to set different values for each one. It must be dependent on differences in the hardware itself, the value remains constant.

## synchronization between cameras

- Use a "mosaic" scene showing all your sources,
- Add an Effect Filter "Render Delay" to every source,
- Enable the websocket server in OBS (Tools / Websocket Server Settings),
- Use a blinking LED or any other clear visual signal and adjust the delay between your sources thanks to the [render delay controler](OBS/control/obs-render-delay.html).

The logic is to delay the camera that displays the signal the first, and align it with the one the displays the signal the last. Repeat for the other cameras. At 25fps, a delta of one frame is visible. Also, because of the duration of the frames (at 25fps, 40ms) it is almost impossible to be 100% perfect. For that, the cameras would need to be synchronized (possible with some modules). But I don't have anything like that so it is not covered here.


Remember that if you restart one or all the services, you may have to make some subtle adjustments. Or not. In my experience most of the times it is OK, but at another times, a couple cameras will need a little help to get in sync.

There is always some small delay between the various sources, that it is quite similar between launches, and that if your scenes do not show the same subjects under various angles, it would not really be necessary to fix it.


If the delay between cameras is more than half a second, I don't know what can be done. Maybe it is possible to stack several render delays (I haven't tried), but the [render delay controler](OBS/control/obs-render-delay.html) only manages the first one. Or maybe try removing the "use_wallclock_as_timestamps" in the ffmpeg script for the video source, and use an "itsoffset" there too (you might also need to recaliber the A/V sync).

The maximum delay I apply is sometimes 200ms, more often 160ms.
