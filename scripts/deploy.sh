sudo mkdir -p /mnt/sdc1 && sudo mkdir -p /mnt/sdc2
sudo mount /dev/sdc1 /mnt/sdc1 -o umask=0000,uid=$(id -u joker),gid=$(getent group share-petalinux | cut -d: -f3)
rm -rfv /mnt/sdc1/*
cp -v $BuildDir/product/* /mnt/sdc1
sync
sudo umount /mnt/sdc1
