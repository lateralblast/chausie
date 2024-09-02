![Chausie cat](https://raw.githubusercontent.com/lateralblast/chausie/master/chausie.jpg)

CHAUSIE
-------

Cloud-Image Host Automation Utility and System Image Engine

Version
-------

Current version 0.4.6

Prerequisites
-------------

Required packages:

- libvirt
- libosinfo-bin
- libguestfs-tools

Introduction
------------

This script is designed to automate/simplify the creation of KVM VMs from cloud images.

I wrote this script as I was tired of Canonical's inconsistent cloud-init support.

I understand having some differences between physical and virtual machines, e.g.
ISO based installs versus using Cloud Images, but when my instructions/workflow for 20.04
and 22.04 stopped working with 24.04, I thought I'd write a script to use virt-customize
to bootstrap the image (e.g. configure network, and SSH keys), install ansible,
then use my existible ansible workflow to finish configuring the VM rather than
using cloud-init.

Usage
-----

You can get help using the -h or --help switch:

```
❯ ./chausie.sh --help
Usage: chausie.sh [OPTIONS...]
-----
 --action)
   Action to perform
 --actions)
   Print actions
 --arch)
   Specify architecture
 --boot*)
   VM boot type (e.g. UEFI)
 --bridge)
   VM network bridge
 --checkconfig)
   Check config
 --cidr)
   VM CIDR
 --cpus)
   Number of VM CPUs
 --cputype)
   Type of CPU within VM
 --debug)
   Run in debug mode
 --dest*)
   Destination of file to copy into VM disk
 --disk)
   VM disk file
 --dns)
   VM DNS server
 --domain*)
   VM domainname
 --dryrun)
   Run in dryrun mode
 --filegroup)
   Set group of a file within VM image
 --fileowner)
   Set owner of a file within VM image
 --fileperms)
   Set permissions of a file within VM image
 --force)
   Force mode
 --fqdn)
   VM FQDN
 --getimage)
   Get Image
 --gateway|--router)
   VM gateway address
 --graphics)
   VM Graphics type
 --gecos)
   GECOS field for user
 --groupid|--gid)
   Group ID
 --group|--groupname)
   Group
 --help|--usage|-h)
   Print help
 --home*)
   Home directory
 --hostname)
   VM hostname
 --imagedir)
   Image directory
 --imagefile)
   Image file
 --imageurl)
   Image URL
 --ip*)
   VM IP address
 --name|--vmname)
   Name of VM
 --nettype)
   Net type (e.g. bridge)
 --netbus|netdriver)
   Net bus/driver (e.g. virtio)
 --netdev|--nic)
   VM network device (e.g. enp1s0)
 --options)
   Options
 --osvariant)
   Os variant
 --osvers)
   OS version of image
 --packages)
   Packages to install in VM
 --password)
   Password for user (e.g. root)
 --poolname)
   Pool name
 --pooldir)
   Pool directory
 --post*)
   Post install script
 --ram)
   Amount of VM RAM
 --size)
   Size of VM disk
 --shellcheck)
   Run shellcheck on script
 --source*|--input*)
   Source file to copy into VM disk
 --sshkey)
   SSH key
 --strict)
   Run in strict mode
 --sudoers)
   Sudoers entry
 --userid|--uid)
   User ID
 --user|--username)
   Username
 --verbose)
   Run in verbose mode
 --version|-V)
   Print version
 --virtdir)
   VM/libvirt base directory

Actions:
-------
 action|help)
   Print actions help
 *config)
   Check config
 connect|console)
   Connect to VM console
 copy|upload)
   Copy file into VM image
 createpool)
   Create pool
 createvm)
   Create VM
 *network*)
   Configure network
 customize|post*)
   Do postinstall config
 deletepool)
   Delete pool
 deletevm)
   Delete VM
 getimage)
   Get image
 *group*)
   Add group to to VM image
 *inject*)
   Inject SSH key into VM image
 install*)
   Install packages in VM image
 listvm*)
   List VMs
 listpool*)
   List pools
 listnet*)
   List nets
 *password*)
   Set password for user in VM image
 run*)
   Run command in VM image
 shellcheck)
   Check script with shellcheck
 shutdown*|stop*)
   Stop VM
 start*|boot*)
   Start VM
 sudo*)
   Add sudoers entry to VM image
 *user*)
   Add user to VM
 version)
   Print version

Options:
-------
 debug)
   Enable debug mode
 dryrun)
   Enable dryrun mode
 dhcp)
   Use DHCP
 force)
   Force action
 noautoconsole)
   Disable autoconsole
 autoconsole)
   Enable autoconsole
 noautostart)
   Disable autostart
 autostart)
   Enable autostart
 nobacking)
   Don't use backing (creates a full copy of image)
 options|help)
   Print options help
 noreboot)
   Disable reboot
 reboot)
   Enable reboot
 strict)
   Enable strict mode
 verbose)
   Enable verbose mode
 version)
   Print version
 ```
