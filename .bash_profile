# /etc/skel/.bash_profile

# This file is sourced by bash for login shells.  The following line
# runs your .bashrc and is recommended by the bash info pages.
if [[ -f ~/.bashrc ]] ; then
	. ~/.bashrc
fi

ac_on=$(acpi -a | cut -d' ' -f3 | cut -d- -f1)

export XDG_VTNR=1
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] ; then
	if [ "$ac_on" = "on" ] ; then
 		exec startx-nvidia
	else
        if [ -n "$(lsmod | grep nvidia)" ]; then
            sudo rmmod nvidia-drm nvidia-modeset nvidia
        fi
		exec startx
	fi
fi
