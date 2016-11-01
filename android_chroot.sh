#!/bin/bash -x

# Bash unofficial 'strict' mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'

#
# Setup variables:
# - check that env.sh has been created
# - load user defined environment variable
# - setup other - internal - variables
ANDROIDCHROOTPATH=`dirname $0`
if [ ! -f $ANDROIDCHROOTPATH/env.sh ]
then
  echo Please edit $ANDROIDCHROOTPATH/env.sh first
  echo cp $ANDROIDCHROOTPATH/env.sh.template $ANDROIDCHROOTPATH/env.sh
fi
source $ANDROIDCHROOTPATH/env.sh
HELPERSPATH=$ANDROIDCHROOTPATH/helpers
IMAGENAME=$CHROOTDIRNAME.img

#
# Create disk image and mount it
#
create_disk_image()
{
  [ ! -d $BUILDPATH ] && mkdir -p $BUILDPATH
  cd $BUILDPATH
  dd if=/dev/zero of=$BUILDPATH/$IMAGENAME bs=$IMAGESIZE count=1
  mkfs.ext2 $BUILDPATH/$IMAGENAME
  mkdir $BUILDPATH/$CHROOTDIRNAME
  sudo mount -o loop -t ext2 $BUILDPATH/$IMAGENAME $BUILDPATH/$CHROOTDIRNAME
}

#
# Run debootstrap - stage 1, on GNU/Linux
#
# As the host and the android system may have different architecture, the host
# takes care of debootstrap's stage 1 (--foreign flag), and debootstrap's stage 2 is performed
# directly on the target device (--second-stage flag).
#
run_debootstrap_stage1()
{
  sudo debootstrap \
    --arch=$ARCH \
    --variant=$VARIANT \
    --foreign \
    $RELEASE $BUILDPATH/$CHROOTDIRNAME \
    http://httpredir.debian.org/debian
}

#
# Add helpers to image, to set proper environment variables, mount and umount
# /proc, /dev, /dev/pts and /sys
#
add_helpers_to_image()
{
  cat $HELPERSPATH/setenv.sh | sudo tee -a $BUILDPATH/$CHROOTDIRNAME/etc/bash.bashrc
}

#
# Umount disk image
#
umount_image()
{
  sudo umount $BUILDPATH/$CHROOTDIRNAME
  zip $BUILDPATH/$IMAGENAME.zip $BUILDPATH/$IMAGENAME
}

# Push disk image to your phone
push_to_phone()
{
  sudo adb push $BUILDPATH/$IMAGENAME.zip $ANDROIDSTORAGE/
}

#
# Generate helpers
#
generate_helpers()
{
  SEDSTMT=""
  for j in ANDROIDSTORAGE CHROOTDIRNAME IMAGENAME
  do
    SEDSTMT="$SEDSTMT;s;__${j}__;${!j};g"
  done
  for i in `ls $HELPERSPATH/*.template`
  do
    sed $SEDSTMT $i > ${i%.template}
  done
}

#
# Push helper and set access rights
#
push_helpers()
{
  sudo adb push $HELPERSPATH/debian_mount.sh $ANDROIDSTORAGE/debian_mount.sh
  sudo adb push $HELPERSPATH/debian_umount.sh $ANDROIDSTORAGE/debian_umount.sh
  sudo adb push $HELPERSPATH/debian_post_install.sh $ANDROIDSTORAGE/debian_post_install.sh
  # TODO Doesn't work for some reasons
  # sudo adb push $HELPERSPATH/userinit.sh /data/local/userinit.sh
  # sudo adb shell busybox chmod +x /data/local/userinit.sh
}

#
# Run debootstrap - stage 2, on Android
#
run_debootstrap_stage2()
{
  sudo adb shell /system/bin/sh -x $ANDROIDSTORAGE/debian_post_install.sh
}

#
# Well done :-)
#
finish()
{
  echo "Well done. To enter your chroot:"
  echo "sudo adb shell"
  echo "cd $ANDROIDSTORAGE && chroot $CHROOTDIRNAME /bin/bash"
  echo "Enjoy!"
}

sudo adb root # First restart adbd as root
create_disk_image
generate_helpers
run_debootstrap_stage1
add_helpers_to_image
umount_image
push_to_phone
push_helpers
run_debootstrap_stage2
finish

