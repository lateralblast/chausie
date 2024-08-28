![Chausie cat](https://raw.githubusercontent.com/lateralblast/chausie/master/chausie.jpg)

CHAUSIE
-------

Cloud-Image Host Automation Utility and System Image Engine

Version
-------

Current version 0.2.4

Prerequisites
-------------

Required packages:

- libvirt
- libosinfo-bin
- libguestfs-tools

Introduction
------------

This script is designed to automate/simplify the creation of KVM VMs from cloud images

Usage
-----

You can get help using the -h or --help switch:

```
❯ ./chausie.sh --help
Usage: chausie.sh [OPTIONS...]
-----

 --action)
 - Action to perform

 --actions)
 - Print actions

 --arch)
 - Specify architecture

 --boot|--boottype)
 - VM boot type (e.g. UEFI)

 --bridge)
 - VM network bridge

 --checkconfig)
 - Check config

 --cpus)
 - Number of VM CPUs

 --cputype)
 - Number of VM CPUs

 --debug)
 - Run in debug mode

 --disk)
 - VM disk file

 --dryrun)
 - Run in dryrun mode

 --force)
 - Force mode

 --getimage)
 - Get Image

 --graphics)
 - VM Graphics type

 --help|--usage|-h)
 - Print help

 --imagedir)
 - Image directory

 --imagefile)
 - Image file

 --imageurl)
 - Image URL

 --hostname|--vmname|--name)
 - Name of VM

 --options)
 - Options

 --osvariant)
 - Os variant

 --osvers)
 - OS version of image

 --poolname)
 - Pool name

 --pooldir)
 - Pool directory

 --ram)
 - Amount of VM RAM

 --size)
 - Size of VM disk

 --strict)
 - Run in strict mode

 --verbose)
 - Run in verbose mode

 --version|-V)
 - Print version

 --virtdir)
 - VM base directory

Actions:
-------

 action|help)
 - Print actions help

 *config)
 - Check config

 connect|console)
 - Connect to VM

 createpool)
 - Create pool

 createvm)
 - Create VM

 customize|post*)
 - Do postinstall config

 deletepool)
 - Create pool

 deletevm)
 - Create VM

 listvm*)
 - List VMs

 listpool*)
 - List VMs

 listnet*)
 - List nets

 shellcheck)
 - Check script with shellcheck

 shutdown*|stop*)
 - Stop VM

 start*|boot*)
 - Start VM

 version)
 - Print version

Options:
-------

 debug)
 - Enable debug mode

 dryrun)
 - Enable dryrun mode

 noautoconsole)
 - Disable autoconsole

 autoconsole)
 - Enable autoconsole

 noautostart)
 - Disable autoconsole

 autostart)
 - Enable autoconsole

 nobacking)
 - Enable strict mode

 options|help)
 - Print options help

 noreboot)
 - Disable reboot

 reboot)
 - Disable reboot

 strict)
 - Enable strict mode

 verbose)
 - Enable verbose mode

 version)
 - Print version
 ```
