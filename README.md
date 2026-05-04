# nuc-cam-streamer
resources related to the streaming of USB cameras connected to a NUC computer running linux.


## per-camera setup

TODO

### udev rules

TODO

### service

TODO

### control script

TODO

## OBS

TODO

### source config

TODO

## sources synchronization

TODO

### A/V

TODO

### synchronization between cameras

- Use a "mosaic" scene showing all your sources,
- Add a filter "render delay" to all your sources,
- Enable the websocket server in OBS (tools / websocket server parameters),
- Use a blinking LED or any other clear visual signal and adjust the delay between your sources thanks to the [render delay controler](OBS/control/obs-render-delay.html).
