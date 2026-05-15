# nuc-cam-streamer

Resources related to the streaming of USB cameras connected to a NUC computer running linux.

## per-camera setup

Having stable names for the cameras makes it easy to create the services dedicated to manage the streaming.

### udev rules

The objective is to have the devices uniquely identified on the computer. Ideally, whatever the port the camera is plugged to, but that is not always possible.

#### camera with serial number

Once a USB camera is plugged:

```bash
lsusb
...
Bus 003 Device 003: ID 046d:0990 Logitech, Inc. QuickCam Pro 9000
...
```

Now use the ID (here 046d:0990) and:

```bash
lsusb -v -d 046d:0990 | grep Serial
```
If you see something like
```bash
...
  iSerial                 2 F4790ED4
...
```
If you have several identical cameras and if you get a different number for each of them, that's good. It means it is possible to write a rule that will create a link to the device with a given name for a given camera.

If there is no serial number, or if it is identical on several devices, one solution is to dedicate a given USB port to a given camera, this is described in the next section.

With those pieces of information (id and serial number), create or edit the rules file:
```bash
sudo vi /etc/udev/rules.d/99-usbcam.rules
```
and add the following:
```bash
SUBSYSTEM=="video4linux", \
   ATTRS{idVendor}=="046d", ATTRS{idProduct}=="0990", ATTRS{serial}=="F4790ED4", \
   ATTR{index}=="0", \
   SYMLINK+="cam1", \
   TAG+="systemd", RUN+="/bin/systemctl restart ffmpeg-cam1.service"
```

This does several things when the corresponding device is plugged:
- it creates a symbolic link with a stable name here "cam1"
- it restarts a dedicated service named "ffmpeg-cam1". For now, it does not exist, it will be covered in another section.


Once done:
```bash
sudo udevadm control --reload
sudo udevadm trigger
```

You should now see a link with the chosen name pointing to the created /dev/videoX. You can also unplug and plug the device again.

Do that for the other cameras, either with this method or with the usb port method described in the next section.

#### per port

To make it easy, unplug everything except your device. Determine your video device, then:
```bash
$ udevadm info /dev/video0 | grep ID_PATH
...
E: ID_PATH_WITH_USB_REVISION=pci-0000:00:14.0-usbv2-0:1:1.0
E: ID_PATH=pci-0000:00:14.0-usb-0:1:1.0
E: ID_PATH_TAG=pci-0000_00_14_0-usb-0_1_1_0
...
```
Replace with the proper device (here /dev/video0). What you want is that "ID_PATH" value (not the other ones).


With those pieces of information (id and usb port), create or edit the rules file:
```bash
sudo vi /etc/udev/rules.d/99-usbcam.rules
```
and add the following:
```bash
SUBSYSTEM=="video4linux", \
   ENV{ID_VENDOR_ID}=="046d", ENV{ID_MODEL_ID}=="085c", \
   ENV{ID_PATH}=="pci-0000:00:14.0-usb-0:9:1.0", ATTR{index}=="0", \
   SYMLINK+="cam1" \
   TAG+="systemd", RUN+="/bin/systemctl restart ffmpeg-cam1.service"
```

This is the same as the other case,but this happens whatever the device as long as it has the proper id and plugged into the right port:
- it creates a symbolic link with a stable name here "cam1"
- it restarts a dedicated service named "ffmpeg-cam1". For now, it does not exist, it will be covered in another section.


Once done:
```bash
sudo udevadm control --reload
sudo udevadm trigger
```

You should now see a link with the chosen name pointing to the created /dev/videoX. You can also unplug and plug the device again.

Do that for the other cameras, either with this method or with the serial number method described in the previous section.

### service

The service is here to automatically restart the service when it crashes, if the camera is unplugged and plugged again.

```bash
# /usr/lib/systemd/system/ffmpeg-cam1.service
[Unit]
Description=FFmpeg SRT stream - cam1
After=dev-cam1.device
Requires=dev-cam1.device
StartLimitBurst=3
StartLimitIntervalSec=30

[Service]
Type=simple
User=your_user
SupplementaryGroups=render video
ExecStart=/usr/local/bin/ffmpeg-cam1.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

If you want to know why I don't define the service in '/etc/systemd/system/', it is because in that case the service cannot be masked.
Meaning that if you have stopped and disabled the service, triggering the rule by plugging a device will start the corresponding service.

So nothing really fancy here. Set the "dev-xxx.device" with the appropriate value.

Set the user you want to use for running the process (User=xxx). Make sure the user belong to the "render" and "video" groups. This may be different on your system. Here this is what I have on Debian Trixie.

As you can see, the service will run the "/usr/local/bin/ffmpeg-cam1.sh" script. We will see that in the next section.

Once your service has been created:
```bash
sudo systemctl daemon-reload
```

The service can be controlled in the usual way with systemd:
```bash
sudo systemctl unmask ffmpeg-cam1
sudo systemctl enable ffmpeg-cam1
sudo systemctl start ffmpeg-cam1
sudo systemctl restart ffmpeg-cam1
sudo systemctl stop ffmpeg-cam1
sudo systemctl disable ffmpeg-cam1
sudo systemctl mask ffmpeg-cam1
```
You can read  what is going on with:
```bash
sudo journalctl -fu ffmpeg-cam1
```

Do that for the other cameras.

### control script

#### common script

See [there](scripts/ffmpeg-cam-common.md)

#### per-camera script

See [there](scripts/ffmpeg-cam1.md)

#### per-camera A/V synchronization

If the method used to stream uses both audio and video sources, then it is possible the audio is out-of-sync.

Usually the audio will be too early compared to the video. I have not encountered the other case, and I guess we will have to forget about the anti-drift measures with the video source, and apply there an itsoffset.

If the audio is playing too early compared to the video, then you only have to define and set a value in the control script such as:
```bash
AUDIO_DELAY=0.24
```
Launch a recording of the source in OBS, and perform a few claps. I use a small web page that plays a beep and shows a signal on screen on a mobile phone.

Why several claps? because a frame has a given duration (40ms for 25fps for example) so you don't really know when your beep should be exactly in the video timeline. By repeating the claps and the measures, you can make an average.


### OSD control

See [there](scripts/OSD-ctl.md)

## OBS

### source config

Use a "media source" for each camera.

Uncheck "local file".

Uncheck "start from the beginning".

Input: srt://<server>:<source port as defined in the script>

Input format: mpegts

Lower the delay if your network allows it.

Use hardware acceleration if possible.

### synchronization between cameras

- Use a "mosaic" scene showing all your sources,
- Add an Effect Filter "Render Delay" to every source,
- Enable the websocket server in OBS (Tools / Websocket Server Settings),
- Use a blinking LED or any other clear visual signal and adjust the delay between your sources thanks to the [render delay controler](OBS/control/obs-render-delay.html).

The logic is to delay the camera that displays the signal the first, and align it with the one the displays the signal the last. Repeat for the other cameras. At 25fps, a delta of one frame is visible. Also, because of the duration of the frames (at 25fps, 40ms) it is almost impossible to be 100% perfect. For that, the cameras would need to be synchronized (possible with some modules). But I don't have anything like that so it is not covered here.


Remember that if you restart one or all the services, you may have to make some subtle adjustments. Or not. In my experience most of the times it is OK, but at another times, a couple cameras will need a little help to get in sync.

There is always some small delay between the various sources, that it is quite similar between launches, and that if your scenes do not show the same subjects under various angles, it would not really be necessary to fix it.


If the delay between cameras is more than half a second, I don't know what can be done. Maybe it is possible to stack several render delays (I haven't tried), but the [render delay controler](OBS/control/obs-render-delay.html) only manages the first one. Or maybe try removing the "use_wallclock_as_timestamps" in the ffmpeg script for the video source, and use an "itsoffset" there too (you might also need to recaliber the A/V sync).

The maximum delay I apply is sometimes 200ms, more often 160ms.
