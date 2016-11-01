# Purpose

Create a loopback-based debian chroot on your Android device, in which you can
do whatever you want (security stuff, development, hosting, etc.). Creating a
chroot manually is very easy, but many errors can occur. This script
consequently provides as much automation as possible, but stops upon errors to
let you investigate what's wrong. If you can fix it, then create a PR. If you
can't, create a new issue.

# Requirements

You need:

- a rooted phone or tabled
- ADB enabled, with root access

Tested with:

- Samsung Galaxy S3 Neo (GT-I9301I)
- CM 12.1-20161031-NIGHTLY-s3ve3g (Android 5.1.1)
- Debian stable/jessie chroot
- Installation from Archlinux

# Usage

## Create chroot (on your GNU/Linux box)

- edit `env.sh` according to your needs
- run `./android_chroot.sh`
- enter the chroot (see below), and follow the [official
  guide](https://wiki.debian.org/chroot#Configuration) to setup the system
  according to your needs

## Use chroot (on your device)

First go in the chroot directory you defined in `env.sh`, then:

- mount chroot filesystem:

  `/system/bin/sh -x ./debian_mount.sh`

- enter chroot:

  `chroot <CHROOTDIRNAME> /bin/bash`

- umount chroot filesystem:

  `/system/bin/sh -x ./debian_umount.sh`

