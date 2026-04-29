#!/bin/bash
#
# reflash image to sd card
#
# VERSION       :1.0.0
# DATE          :2025-07-09
# URL           :based on https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :original by Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Check current filesystem type
ROOT_FS_TYPE="$(sed -n -e 's|^/dev/\S\+ /media/root-ro/overlay/lower \(btrfs\) .*$|\1|p' /proc/mounts)"
test "$ROOT_FS_TYPE" == btrfs && exit 100

panel_version=80
/usb_flash/fbtextdemo -c /home/debian/UI/qml/fonts/BarlowSemiCondensed-SemiBold.ttf "Don't panic" -w 800 -h 800 -f 100 -y 200 -x 1000
sed -i 's/dep_add_modules_mount \/$//g' /usr/share/initramfs-tools/hook-functions
if [ -d /mnt/temp_boot/boot ]; then 
	sed -i 's/cma=512M/cma=512M skipoverlay overlayroot=disabled/g' /mnt/temp_boot/boot/boot.cmd
    grep -q w500hdc023 /mnt/temp_boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb && panel_version=23
    grep -q w500hdc019 /mnt/temp_boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb && panel_version=19

else
	sed -i 's/cma=512M/cma=512M skipoverlay overlayroot=disabled/g' /boot/boot.cmd
    grep -q w500hdc023 /boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb  && panel_version=23
    grep -q w500hdc019 /boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb && panel_version=19
fi
cp /usb_flash/fbtextdemo /usr/lib/

echo $panel_version > /usb_flash/panel_version
test -f /pedal_state/hardware_info.json && cp /pedal_state/hardware_info.json /usb_flash/

# Copy gzip, xargs and fbtextdemo to initrd
cat > /etc/initramfs-tools/hooks/flash_iso <<"EOF"
#!/bin/sh

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions
copy_file thing /usb_flash/fbtextdemo /usr/lib
copy_exec /usr/bin/xargs /usr/bin
copy_exec /usr/bin/gzip /usr/bin
copy_file thing /usr/bin/pv /usr/lib
copy_exec /usr/bin/mount /usr/bin
copy_exec /usr/bin/cat /usr/bin
copy_file font /home/debian/UI/qml/fonts/BarlowSemiCondensed-SemiBold.ttf /usr/lib

manual_add_modules pwm_sun4i jffs2 zlib_deflate asix axp20x_adc axp20x_battery axp20x_usb_power uas axp20x_ac_power industrialio goodix gpio_keys_polled pwm_bl input_polldev pinctrl_axp209 phy_sun6i_mipi_dphy sun6i_mipi_dsi lima gpu_sched

EOF

chmod +x /etc/initramfs-tools/hooks/flash_iso

# Execute flash before mounting root filesystem
cat > /etc/initramfs-tools/scripts/init-premount/flash_poly <<"EOF"
#!/bin/sh

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

echo "Starting ${ROOT} conversion"

# Waiting for device creation
while true                    
do                                                
	test -e /dev/sda1         
	if [ $? -eq 0 ]; then
		echo "Device created";            
		break;       
	else                          
		echo "Waiting for USB device";        
		sleep 1;     
	fi                                
done

/usr/lib/fbtextdemo -c /usr/lib/BarlowSemiCondensed-SemiBold.ttf "Updating. Wait 20 mins." -w 800 -h 800 -f 100 -y 200 -x 1000
mkdir -p /usb_flash
mount /dev/sda1 /usb_flash
echo "usb mounted" >> /usb_flash/debugrun
echo "usb mounted"

ls /usb_flash
# copy image from USB to drive
#gzip -kcd /usb_flash/beebo_407.img.gz.* > /dev/mmcblk0 
gunzip --help 2> /usb_flash/debugrun

cat /usb_flash/beebo_407.img.gz.* | gunzip 2> /dev/null | /usr/lib/pv -n -p -s 15619604992 2>&1 > /dev/mmcblk0 | xargs -n1 /usr/lib/fbtextdemo -c /usr/lib/BarlowSemiCondensed-SemiBold.ttf -w 800 -h 800 -f 100 -y 200 -x 1000
echo "image copied"
echo "image copied" >> /usb_flash/debugrun
sync /dev/mmcblk0

/usr/lib/fbtextdemo -c /usr/lib/BarlowSemiCondensed-SemiBold.ttf "2. Dont remove USB. Restart pedal" -w 800 -h 800 -f 100 -y 200 -x 1000

EOF

chmod +x /etc/initramfs-tools/scripts/init-premount/flash_poly
# check if panel file has been copied if file system is already btrfs in local-bottom

# after filesytems are mounted, copy the correct device tree to the boot
cat > /etc/initramfs-tools/scripts/local-bottom/copy_panel <<"EOF"
#!/bin/sh

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

echo "Copying panel files"
/usr/lib/fbtextdemo -c /usr/lib/BarlowSemiCondensed-SemiBold.ttf "Copying panel file" -w 800 -h 800 -f 100 -y 200 -x 1000
mkdir -p /usb_flash
mount /dev/sda1 /usb_flash
# copy panel from USB to drive
mount /dev/mmcblk0p1 /boot
echo "running copy panel in install update" >> /usb_flash/debugrun
panel_version=$(cat /usb_flash/panel_version)
test -f /usb_flash/hardware_info.json && cp /usb_flash/hardware_info.json /pedal_state/
cp /usb_flash/panel_version /pedal_state/
# copy TST if newer
test $panel_version -gt 24 && cp /usb_flash/tsd_panel.dtb /boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb
# copy 23
test $panel_version -lt 24 && cp /usb_flash/23_panel.dtb /boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb
# copy 18 if older
test $panel_version -lt 20 && cp /usb_flash/18_panel.dtb /boot/boot/dtb/allwinner/sun50i-a64-sopine-baseboard.dtb
/usr/lib/fbtextdemo -c /usr/lib/BarlowSemiCondensed-SemiBold.ttf "Update done" -w 800 -h 800 -f 100 -y 200 -x 1000
sync /dev/mmcblk0p1
/usr/lib/fbtextdemo -c /usr/lib/BarlowSemiCondensed-SemiBold.ttf "3. Dont remove USB. Restart pedal" -w 800 -h 800 -f 100 -y 200 -x 1000

EOF

chmod +x /etc/initramfs-tools/scripts/local-bottom/copy_panel

/usb_flash/fbtextdemo -c /home/debian/UI/qml/fonts/BarlowSemiCondensed-SemiBold.ttf "Building updater 407" -w 800 -h 800 -f 100 -y 200 -x 1000
# Regenerate initrd
update-initramfs -v -u -k `uname -r`
mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr

# if [ -d /mnt/temp_boot/boot ]; then 
# 	mkimage -C none -A arm -T script -d /mnt/temp_boot/boot/boot.cmd /mnt/temp_boot/boot/boot.scr
# 	cp -f /boot/uInitrd-5.4.2-rt5-001 /mnt/temp_boot/boot/
# else
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
cp -f /boot/uInitrd-5.4.2-rt5-001 /overlay/lower/boot/
cp -f /boot/boot.cmd /overlay/lower/boot/
cp -f /boot/boot.scr /overlay/lower/boot/
# fi

# Remove files
rm -f /etc/initramfs-tools/hooks/flash_iso /etc/initramfs-tools/scripts/init-premount/flash_poly
rm -f /etc/initramfs-tools/scripts/local-bottom/copy_panel

sync
/usb_flash/fbtextdemo -c /home/debian/UI/qml/fonts/BarlowSemiCondensed-SemiBold.ttf "Dont remove USB. Restart pedal now" -w 800 -h 800 -f 100 -y 200 -x 1000

# List files in initrd
# lsinitramfs /boot/initrd.img-*-amd64
