#!/bin/bash
ROOT_FS_TYPE="$(sed -n -e 's|^/dev/\S\+ /overlay/lower \(btrfs\) .*$|\1|p' /proc/mounts)"
# test "$ROOT_FS_TYPE" == btrfs
CUR_VER=$(sed -n -e 's|.* FIRMWARE \([0-9]*\)"|\1|p' /home/debian/UI/qml/Settings.qml)
OVROOT=$(sudo which overlayroot-chroot)
mount | grep overlay
HAS_OVERLAY=$?
# check if we're already btrfs
echo "start debug.sh"
echo "start 407" > /usb_flash/debugrun
if [ $CUR_VER -ge 403 ]; then
	# check if panel state is written or not
	echo "update is installed" >> /usb_flash/debugrun
    sync /usb_flash/debugrun
	echo "checking panel state"
	test -f /pedal_state/panel_updated4 
	if [ $? -eq 0 ]; then
		echo "panel updated" >> /usb_flash/debugrun
	   	#exit 100
	else
		/bin/bash /usb_flash/copy_panel.sh
	fi

	if [ $CUR_VER -lt 408 ]; then
		mount --rbind /dev /overlay/lower/dev 
		mount --rbind /usb_flash /overlay/lower/usb_flash 
		$OVROOT /bin/bash <<"EOT"
tar -C / -xzf  /usb_flash/beebo_update_408.tar.gz
sync
EOT
		sleep 5
		reboot
	fi
else
	echo "update not yet installed" >> /usb_flash/debugrun
    sync /usb_flash/debugrun
	echo "update not done yet, doing it"
	systemctl stop ingen --no-block
	systemctl stop polyui --no-block
	systemctl stop display-manager.service --no-block
	sleep 5
	
	if [ $HAS_OVERLAY -eq 0 ]; then
		echo "has overlay" >> /usb_flash/debugrun
		if [ "$ROOT_FS_TYPE" == "btrfs" ]; then
			echo "is already btrfs" >> /usb_flash/debugrun
			mount --rbind /dev /overlay/lower/dev 
			mount --rbind /usb_flash /overlay/lower/usb_flash 
			mount /dev/mmcblk0p1 /overlay/lower/mnt/temp_boot
			$OVROOT /bin/bash /usb_flash/install_update.sh
		else
			echo "is not btrfs" >> /usb_flash/debugrun
			mount --rbind /dev /media/root-ro/dev
			mount --rbind /usb_flash /media/root-ro/usb_flash 
			$OVROOT /bin/bash /usb_flash/install_update.sh
		fi
	else
		echo "does not have overlay" >> /usb_flash/debugrun
		if [ "$ROOT_FS_TYPE" == "btrfs" ]; then
			mount /dev/mmcblk0p1 /mnt/temp_boot
		fi
		/bin/bash /usb_flash/install_update.sh
	fi
	# reboot
fi
