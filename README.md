![Chausie cat](https://raw.githubusercontent.com/lateralblast/chausie/master/chausie.jpg)

CHAUSIE
-------

Cloud-Image Host Automation Utility and System Image Engine

License
-------

CC BY-SA: https://creativecommons.org/licenses/by-sa/4.0/

Fund me here: https://ko-fi.com/richardatlateralblast

Version
-------

Current version 1.4.9

Supported Distributions
-----------------------

- Ubuntu
- Alma Linux
- Rocky Linux
- Debian Linux
- OPNsense

Defaults
--------

The defualt username and passwords are set to debian, ubuntulinux, almalinux and rocky

Issues
------

Current Issues:
- Debian, Rocky, Alma Linux currently only support cloud-init changing the default user password

Prerequisites
-------------

Required packages:

- libvirt
- libosinfo-bin
- libguestfs-tools
- whois (mkpasswd)
- virt-manager
- cloud-image-utils
- ipcalc
- pbzip2
- genisoimage (Linux)
- mkisofs (MacOS)

Example command to install packages on Ubuntu:

```
sudo apt install -y libosinfo-bin libguestfs-tools whois virt-manager cloud-image-utils ipcalc
```

You'll also need to configure network bridges (the default is br0, but can be changed)
if you want to use the default settings. You could configure it with NAT, or internal/
host-only networking, but I haven't looked at those options yet.

Configuring bridges on Ubuntu can be done on Ubuntu by editing the netplan file located in /etc/netplan.

An example of a netplan file wihout bridges configured:

```
network:
  ethernets:
    eno1:
      addresses: [192.168.10.63/22]
      nameservers:
        addresses: [8.8.8.8]
      routes:
        - to:  default
          via: 192.168.11.254
  version: 2
```

An example of a netplan file with bridges configured:

```
network:
  ethernets:
    eno1:
      dhcp4: false
  bridges:
    br0:
      interfaces: [eno1]
      addresses: [192.168.10.63/22]
      nameservers:
        addresses: [8.8.8.8]
      routes:
        - to:  default
          via: 192.168.11.254
  version: 2
```

Once the change has been done it can be enabled by:

```
sudo netplan apply
```

Introduction
------------

This script is designed to automate/simplify the creation of KVM VMs from cloud images.

Background
----------

I wrote this script as I was tired of Canonical's inconsistent cloud-init support.

I understand having some differences between physical and virtual machines, e.g.
ISO based installs versus using Cloud Images, but when my instructions/workflow for 20.04
and 22.04 stopped working with 24.04, I thought I'd write a script to help handle these
inconsistencies for cloud images.

This script is also able do updates to images using virt-customize to bootstrap the image
(e.g. configure network, and SSH keys) if needed, and then use my existing ansible workflow
to finish configuring the VM rather than using cloud-init.

The script also support hardware pass-through, making it slighty easier to configure that
(you still need to the host side and inside the VM) with the --hostdevice switch which
you can pass the host PCI ID to, e.g.

```
./chausie.sh --action createvm --hostdevice 04:00.0
```

If you want more information on the system and software side of this you can look at the
example documentation I created for Nvidia GPU pass-through here:

https://github.com/lateralblast/kvm-nvidia-passthrough

Usage
-----

More detailed examples can be found here:

https://github.com/lateralblast/chausie/wiki

The default username and password used with images is "cloudadmin"

By default the script will try to create a VM using a cloud-init config.
If you wish to create an image without cloud-init and do manual modifications
via virt-customize (which can also be driven by the script to make it easier),
then use the option nolocalds, e.g.

```
./chausie --action createvm --option nolocalds
```

If you want to set mulitple options, e.g. enable verbose and dryrun modes,
ou can include both of them in after the --option switch, separated by a comma, e.g.

```
./chausie.sh --action createvm --options verbose,dryrun
```

Similarly, if you want to set mulitple options, e.g. listvms and listpools,
you can include both of them in after the --option switch, separated by a comma, e.g.

```
./chausie.sh --action listvms,listpools
```

Obviously you need to be careful about chaining actions, e.g.
you need to add user before injecting keys and adding to sudoers,
so you'd order those actions:

```
./chausie.sh --action user,injectkeys,sudoers --user ubuntu --name test
```

You can get usage information by usign the --help switch.
This will return information about the standard switches.

```
./chausie.sh --help
```

If you want specific information about just the actions or options,
you can get this by using the --help switch folled by actions, or options.

```
./chausie.sh --help actions
```

If you want full help, i.e. standard switches, actions, and options,
use the --help switch followed by full/all.

Examples
--------

List VMs:

```
./chausie.sh --action listvms
 Id   Name   State
-----------------------
 -    test   shut off
```

List Pools:

```
./chausie.sh --action listpools
 Name   State    Autostart
----------------------------
 test   active   no
```

List Nets:

```
./chausie.sh --action listnets
 Name      State      Autostart   Persistent
----------------------------------------------
 default   inactive   no          yes
```

Create VM with latest LTS cloud image and default settings:

```
./chausie.sh --action createvm --name test
Formatting '/var/lib/libvirt/images/test/test.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=21474836480 backing_file=/var/lib/libvirt/images/releases/ubuntu-24.04-server-cloudimg-amd64.img backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16

Starting install...
Creating domain...                                                                                                                                                                    |    0 B  00:00:00
Domain creation completed.
You can restart your domain by running:
  virsh --connect qemu:///system start test
```

Create a VM with default username and password, HWE kernel, static IP, and pass through PCI device from host: 

```
./chausie.sh --action createvm --ip 192.168.10.74 --cidr 22 --gateway 192.168.11.254 --size 50G --release 24.04 --hostname gpuvm04 --hostdevice "03:00.0" --options verbose,hwe
```

Create default user (ubuntu), inject SSH keys, and add to sudoers:

```
./chausie.sh --action user,injectkeys,sudoers --name test
```

Set root password:

```
./chausie.sh --action password --user root --password P455w0rd --name test
```

Delete VM:

```
./chausie.sh --action deletevm --name test
```

Start VM:

```
./chausie.sh --action startvm --name test
```

Connect to VM via console:

```
./chausie.sh --action connect --name test
```

Start VM and connect to VM in one command:

```
./chausie.sh --action startvm,connect --name test
```

Stop VM:

```
./chausie.sh --action stopvm --name test
```

Restart VM:

```
./chausie.sh --action restartvm --name test
```

Create snapshot:

```
./chause.sh --action createsnap --name test
```

List snapshots:

```
./chause.sh --action listsnaps --name test
```

Restore snapshot:

```
./chausie.sh --action restoresnap --snap test_snap_20251605001640 --hostname test
```

Delete snapshot:

```
./chausie.sh --action deletesnap --snap test_snap_20251605001640 --hostname test
```

Configure passthrough for host device 04:00.0:

```
./chausie.sh --action passthrough --device "04:00.0"
```
