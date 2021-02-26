# Power Driven Optimus

This repository aims to extend battery life on NVIDIA Optimus driven laptops
when on battery by starting X with the integrated GPU when on battery.  
This was only tested on Gentoo but feel free to try this setup on different
distros.

## Dependencies

This setup only works with acpi and xinit at the moment (sys-power/acpi and
x11-apps/xinit)  
Obviously the proprietary nvidia-drivers are needed too.

## Overview

On bash login the current power state is evaluated. Depending on the state (ac
or battery) X is started with different configurations.  
The power state is evaluated in `.bash_profile` where also the start script is
executed. Note that instead it would be possible to just rename configuration
files which is probably a cleaner way.

## Setup

Every change here (except the startx script) can be found in a sample file in
this repository.

### `.bash_profile`

Append those lines to your `.bash_profile` in your home dir:

```bash
ac_on=$(acpi -a | cut -d' ' -f3 | cut -d- -f1)

export XDG_VTNR=1
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] ; then
	if [ "$ac_on" = "on" ] ; then
 		exec startx-nvidia
	else
        if [ -n "$(lsmod | grep nvidia)" ]; then
            # For convenience disable password for the following command
            sudo rmmod nvidia-drm nvidia-modeset nvidia
        fi
		exec startx
	fi
fi
```

### `.xserverrc-nvidia`

Create a file `.xserverrc-nvidia` in your home dir with the following content:

```bash
#!/bin/sh
if [ -z "$XDG_VTNR" ]; then
  exec /usr/bin/X -nolisten tcp "$@" -configdir xinit-nvidia
else
  exec /usr/bin/X -nolisten tcp -keeptty "$@" "vt$XDG_VTNR" -configdir xinit-nvidia
fi
```

You can omit `-nvidia` in the file name and just move the file when you don't
want to copy the startx script.

### `.xinitrc-nvidia`

Put these lines right before the start of your window manager:

```bash
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto  # propably not necessary because you probably setup xrandr elsewhere
```

### `startx-nvidia`

Copy the startx script:
```
# cp /usr/bin/startx /usr/bin/startx-nvidia
```

Change the appropriate lines: (this can be done with file copying so this script
isn't needed)
```bash
userclientrc=$HOME/.xinitrc-nvidia

userserverrc=$HOME/.xserverrc-nvidia
```

Search for the string `xinit "$client"` load the nvidia kernel module before and
unload it after:

```bash
sudo modprobe nvidia-drm
xinit "$client" $clientargs -- "$server" $display $serverargs
sudo rmmod nvidia-drm nvidia-modeset nvidia
```

Setting NOPASSWD for the module loading commands with visudo can be convenient.
The last step may not be necessary, but I'm too lazy right now to test it out.
I'll update this when I have time.

### `/etc/X11/xinit-nvidia/10-nvidia.conf`

Create the directory:

```
# mkdir /etc/X11/xinit-nvidia
```

Create the file `10-nvidia.conf` with following content (BusID may be
different):

```
Section "ServerLayout"
    Identifier "layout"
    Screen 0 "nvidia"
    Inactive "intel"
EndSection

Section "Device"
    Identifier "nvidia"
    Driver "nvidia"
    BusID "01:00:0"
    Option "RegistryDwords" "EnableBrightnessControl=1"
EndSection

Section "Screen"
    Identifier "nvidia"
    Device "nvidia"
    Option "AllowEmptyInitialConfiguration"
EndSection

Section "Device"
    Identifier "intel"
    Driver "modesetting"
EndSection

Section "Screen"
    Identifier "intel"
    Device "intel"
EndSection
# This xorg.conf.d configuration snippet configures the X server to
# automatically load the nvidia X driver when it detects a device driven by the
# nvidia-drm.ko kernel module.  Please note that this only works on Linux kernels
# version 3.9 or higher with CONFIG_DRM enabled, and only if the nvidia-drm.ko
# kernel module is loaded before the X server is started.

Section "OutputClass"
    Identifier     "nvidia"
    MatchDriver    "nvidia-drm"
    Driver         "nvidia"
EndSection
```
