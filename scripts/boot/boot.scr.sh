echo "Trying to program fpga bitstream"
bitstream_image=system.bit
bitstream_address=0x01000000
mmcinfo
if test -e mmc 0:1 ${bitstream_image}; then
	fatload mmc 0:1 ${bitstream_address} ${bitstream_image} # ${filesize} is set
	fpga loadb 0 ${bitstream_address} ${filesize}
	echo "Programing FPGA bitstream success"
else
	echo "No FPGA bitstream file in sd card!"
fi

echo "Trying to load system.dtb"
device_tree_address=0x02000000
if test -e mmc 0:1 /system.dtb; then
	fatload mmc 0:1 ${device_tree_address} system.dtb
else
	echo "No system.dtb file in sd card!"
	exit
fi

echo "Trying to boot Linux zImage"
kernel_address=0x03000000
if test -e mmc 0:1 /zImage; then
	fatload mmc 0:1 ${kernel_address} zImage
else
	echo "No zImage file in sd card!"
	exit
fi

echo "Booting Linux Kernel......"
bootz ${kernel_address} - ${device_tree_address};

echo "Can't boot linux!"
