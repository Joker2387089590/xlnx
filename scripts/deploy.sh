sudo mount /dev/sd*1 /mnt/sdc1 -o umask=0000,uid=1001
sudo mount /dev/sd*2 /mnt/sdc2
rm -rf /mnt/sdc1/*
cp -v $BuildDir/product/* /mnt/sdc1
sudo umount /mnt/sdc*
