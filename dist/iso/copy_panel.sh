#!/bin/bash
echo "Copying panel files"
/usb_flash/fbtextdemo -c /home/debian/UI/qml/fonts/BarlowSemiCondensed-SemiBold.ttf "Copying panel file" -w 800 -h 800 -f 100 -y 200 -x 1000
# copy panel from USB to drive
mount /dev/mmcblk0p1 /boot
panel_version=$(cat /usb_flash/panel_version)
test -f /usb_flash/hardware_info.json && cp /usb_flash/hardware_info.json /pedal_state/
cp /usb_flash/panel_version /pedal_state/
# copy TST if newer
test $panel_version -gt 23 && cp /usb_flash/tsd_panel.dtb /boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb
# copy 23
test $panel_version -lt 24 && cp /usb_flash/23_panel.dtb /boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb
# copy 18 if older
test $panel_version -lt 20 && cp /usb_flash/18_panel.dtb /boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb
/usb_flash/fbtextdemo -c /home/debian/UI/qml/fonts/BarlowSemiCondensed-SemiBold.ttf "Update done" -w 800 -h 800 -f 100 -y 200 -x 1000
echo 1 > /pedal_state/panel_updated4
sync /dev/mmcblk0
