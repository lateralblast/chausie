# Changelog

All notable changes to this project are documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.6.4] - 2026-10-02

### Added
- Added serial console (console=ttyS0,115200n8) and visible grub menu to generated imagecraft yaml
- Added netplan network part to imagecraft yaml, DHCP via --options dhcp (or no --ip), static otherwise
- Added consoledev and consolespeed defaults
- Added --buildbase switch and automatic imagecraft build base selection
- Added gir1.2-freedesktop-dev, gir1.2-girepository-2.0, gir1.2-girepository-2.0-dev and gir1.2-glib-2.0-dev to required Linux packages
- Added 30s timeout drop-in for systemd-networkd-wait-online in imagecraft yaml (boot stalls on 26.04/26.10 otherwise)
- Added chmod 600 of generated netplan file in imagecraft yaml
- Added --cloudinit switch and cloudinit option to build an imagecraft image for use with cloud-init (no baked root password or netplan, NoCloud datasource, empty machine-id), VM is created with a cloud-init seed disk
- Added --cloudinitfile switch to specify the path of the generated cloud-init config file

### Changed
- Removed the --cloud* wildcard switch, the cloud-init config file switch is now --cloudinitfile (previously --cloud, --cloudinit, etc. took a file)
- Added imagecraft, snap, and new package prerequisites to README, and an Imagecraft Images section

### Fixed
- Fixed dryrun writing the imagecraft yaml into the releases directory (now written to /tmp)
- Fixed spurious image creation error in dryrun mode
- Fixed imagecraft failing for 26.04 as the snapcraft multipass remote has no such image (build base now falls back to 24.04)
- Fixed imagecraft rejecting build-base ubuntu@26.10 (development release is now written as devel)
- Fixed virt-install failing with unknown OS name for releases missing from osinfo-db (e.g. ubuntu26.10), now falls back to newest known Ubuntu variant
- Fixed nested quoting in execute_command/run_command so multi-word virt-customize --run-command and --install arguments reach the guest intact
- Fixed create_keys failing when host keys already exist (imagecraft images ship with baked-in host keys), now removes and regenerates all with ssh-keygen -A

## [1.6.3] - 2026-10-01

### Added
- Added --swapsize switch
- Added --bootsize switch
- Added initial imagecraft yaml file creation

### Fixed
- Fixed typo in packager header
- Fixed quoting in imagecraft file notice message
- Fixed duplicate imagename default
- Fixed snap list failing on hosts without snap
- Fixed imagecraft check using sudo outside execute_command
- Fixed rootsize default referencing removed defaults['size']
- Fixed MB sizes (e.g. 512M) being truncated to 0G

## [1.6.2] - 2026-09-21

### Fixed
- Fixed get_cidr fallback picking up netmasks from unrelated interfaces

## [1.6.1] - 2026-09-21

### Fixed
- Fixed always-true condition in get_cidr that discarded a successful ip route lookup

## [1.6.0] - 2026-09-21

### Fixed
- Fixed Ubuntu and Debian codename/release lookup table typos and missing entry

## [1.5.9] - 2026-09-21

### Added
- Added missing -- prefix to --backup and --netdriver switches

## [1.5.8] - 2026-09-21

### Fixed
- Fixed --customise and --setpass switches not matching their action cases

## [1.5.7] - 2026-09-21

### Fixed
- Fixed customize_vm virt-customize call and default postscript path

## [1.5.6] - 2026-09-21

### Fixed
- Fixed broken snapshot timestamp generation in create_snapshot

## [1.5.5] - 2026-09-21

### Fixed
- Fixed inverted guard in passthrough_device that warned when devicetype was set

## [1.5.4] - 2026-09-21

### Fixed
- Fixed wrong loop variable and PCI bus ID extraction in passthrough_device

## [1.5.3] - 2026-09-21

### Fixed
- Fixed inverted owner/group logic in upload_file chown command

## [1.5.2] - 2026-09-21

### Changed
- Wired up disk size unit handling and fixed unit check to use vm size

## [1.5.1] - 2026-09-21

### Fixed
- Fixed bad substitution in inject_key sshkeyfile warning message

## [1.5.0] - 2026-08-10

### Added
- Added updates option for installing updates

## [1.4.9] - 2026-08-10

### Added
- Added wazuh to apps selection

## [1.4.8] - 2026-08-10

### Changed
- Improved runcmd handling

## [1.4.7] - 2026-08-10

### Added
- Added disk size unit handling

## [1.4.6] - 2026-08-10

### Added
- Added app switch and initial app support

### Changed
- Updated action and option array processing

## [1.4.5] - 2026-08-10

### Changed
- Changed default ubuntu username and password due to it not being created/set

## [1.4.4] - 2026-08-10

### Added
- Added example start command to output when creating VM

## [1.4.3] - 2026-08-10

### Changed
- Updated cpu switch

## [1.4.2] - 2026-08-10

### Added
- Added ability to query multiple items from VM

## [1.4.1] - 2026-08-08

### Added
- Added routine to get VM info

## [1.4.0] - 2026-08-07

### Added
- Added code to handle M/G in memory value

## [1.3.9] - 2026-08-07

### Added
- Added --vcpus and --memory switches

## [1.3.8] - 2026-08-04

### Added
- Added initial Debian Linux support

## [1.3.7] - 2026-08-03

### Added
- Added inital Rock Linux support

## [1.3.6] - 2026-08-04

### Fixed
- Fixed chained actions

## [1.3.5] - 2026-08-04

### Changed
- Started to add OS specific defaults

## [1.3.4] - 2026-08-03

### Fixed
- Fixed network interface for Alma Linux

## [1.3.3] - 2026-08-03

### Changed
- More initial Alma Linux support

## [1.3.2] - 2026-08-03

### Added
- Added chpasswd and pwauth options

## [1.3.1] - 2026-08-02

### Fixed
- Fixed mkisofs command for MacOS (cloud-localds replacement)

## [1.3.0] - 2026-08-02

### Added
- Added handling for ISO architecture string being different for different distributions

## [1.2.9] - 2026-08-02

### Added
- Added initial handling for Alma Linux

## [1.2.8] - 2026-08-01

### Changed
- Replaced bzip2 with pbzip2

## [1.2.7] - 2026-08-01

### Changed
- Improved opnsense support

## [1.2.6] - 2026-08-01

### Changed
- More opnsense support

## [1.2.5] - 2026-08-01

### Fixed
- Fixed ability for script to run further in dry run mode

## [1.2.4] - 2026-08-01

### Added
- Added CPU type determination for opnsense

## [1.2.3] - 2026-08-01

### Added
- Added initial support for opnsense

## [1.2.2] - 2026-08-01

### Changed
- Applied shellcheck recommendations

## [1.2.1] - 2026-07-31

### Added
- Added osname switch and libvirt-dev package requirement

## [1.2.0] - 2026-05-19

### Added
- Added fix for osvariant with Ubuntu 26.04

## [1.1.9] - 2026-05-19

### Added
- Added separate actions to command line parsing section

## [1.1.8] - 2026-05-18

### Added
- Added Ubuntu 26.04 to default Ubuntu releases

## [1.1.7] - 2026-05-18

### Added
- Added actions_list array

## [1.1.6] - 2026-05-18

### Added
- Added options_list array

## [1.1.5] - 2026-05-18

### Added
- Added checkconfig switch

## [1.1.4] - 2025-08-10

### Changed
- Fixes based on shellcheck

## [1.1.3] - 2025-08-10

### Changed
- Improved passthrough module determination

## [1.1.2] - 2025-08-10

### Added
- Added config switch

## [1.1.1] - 2025-08-10

### Changed
- Updated passthrough commands to run through execute_command

## [1.1.0] - 2025-08-10

### Added
- Added code to change permissions on config files

## [1.0.9] - 2025-08-10

### Added
- Added 2 second sleep between multiple actions

## [1.0.8] - 2025-08-10

### Added
- Added halt action to shutdown

## [1.0.7] - 2025-08-08

### Added
- Added handling for development releases

## [1.0.6] - 2025-08-06

### Added
- Initial code for passthrough configuration

## [1.0.5] - 2025-08-06

### Added
- Added destroy

## [1.0.4] - 2025-08-06

### Added
- Added code to reboot/bounce VM

## [1.0.3] - 2025-08-05

### Added
- Added suspend and resume functions

## [1.0.2] - 2025-08-05

### Changed
- Adjusted warning_message routine

## [1.0.1] - 2025-08-05

### Added
- Added runcmd section

## [1.0.0] - 2025-08-05

### Added
- Added seperate function for warning message

## [0.9.9] - 2025-08-05

### Added
- Added functions to create, restore and destroy snapshots

## [0.9.8] - 2025-08-04

### Added
- Added reset VM function and updated README

## [0.9.7] - 2025-08-04

### Added
- Added reset before console command to deal with terminal issues

## [0.9.6] - 2025-08-04

### Added
- Added support for zsh as a shell

## [0.9.5] - 2025-08-04

### Fixed
- Fixed shell for Ubuntu 18.04

## [0.9.4] - 2025-08-04

### Added
- Added support for multiple IPs and DNS

## [0.9.3] - 2025-08-01

### Added
- Added secureboot handling

## [0.9.2] - 2025-07-31

### Changed
- Improvements

## [0.9.1] - 2025-07-31

### Changed
- Improved passthrough support

## [0.9.0] - 2025-07-31

### Added
- Added HWE kernel support

## [0.8.9] - 2025-07-31

### Added
- Added defaults

## [0.8.8] - 2025-07-30

### Fixed
- Bug fixes

## [0.8.7] - 2025-07-30

### Changed
- Improved VM state check

## [0.8.6] - 2025-07-30

### Changed
- Improved check if vm exists

## [0.8.5] - 2025-07-30

### Changed
- Merged check disk and create disk functions

## [0.8.4] - 2025-07-30

### Changed
- Improved handling of VM name

## [0.8.3] - 2025-07-30

### Changed
- Cleaned up script according to shellcheck recommendations

## [0.8.2] - 2024-12-04

### Changed
- Improved nameserver determination

## [0.8.1] - 2024-12-04

### Fixed
- Fixed bug with CIDR determination

## [0.8.0] - 2024-09-18

### Changed
- Updated documentation

## [0.7.9] - 2024-09-18

### Added
- Added code to convert codename to release version

## [0.7.8] - 2024-09-18

### Added
- Added whois to required package list (for mkpasswd)

## [0.7.7] - 2024-09-18

### Fixed
- Fixed --bridge switch

## [0.7.6] - 2024-09-18

### Fixed
- Fixed CIDR check on Linux when there are multiple interfaces

## [0.7.5] - 2024-09-18

### Removed
- Removed --checkconfig switch and fixed some bugs

## [0.7.4] - 2024-09-11

### Changed
- Improved CIDR determination on Linux

## [0.7.3] - 2024-09-10

### Added
- Added ipcalc to required packages on MacOS

## [0.7.2] - 2024-09-10

### Added
- Added code to install cloud-localds on MacOS

## [0.7.1] - 2024-09-09

### Fixed
- Fixed CIDR determination

## [0.7.0] - 2024-09-09

### Added
- Added code to determine DNS

## [0.6.9] - 2024-09-09

### Added
- Added code to determine CIDR

## [0.6.8] - 2024-09-09

### Changed
- Updated default group

## [0.6.7] - 2024-09-06

### Added
- Added mask function

## [0.6.6] - 2024-09-06

### Changed
- Cleaned uo action(s) and option(s) switches

## [0.6.5] - 2024-09-05

### Fixed
- Bug fixes and improvements

## [0.6.4] - 2024-09-04

### Added
- Added code to support hardware pass-through and features

## [0.6.3] - 2024-09-04

### Changed
- Updated code for handling SSH keys

## [0.6.2] - 2024-09-04

### Changed
- Updated default user

## [0.6.1] - 2024-09-04

### Changed
- Fixes for cloud-init package list

## [0.6.0] - 2024-09-04

### Added
- Added code to set GECOS field if not set

## [0.5.9] - 2024-09-04

### Changed
- Updated crypt command for Linux

## [0.5.8] - 2024-09-04

### Fixed
- Bug fixes for VM check

## [0.5.7] - 2024-09-04

### Fixed
- Bug fixes for DHCP

## [0.5.6] - 2024-09-04

### Changed
- More cloud-init support and bug fixes

## [0.5.5] - 2024-09-04

### Added
- Added initial cloud-init support and ran script through shellcheck

## [0.5.4] - 2024-09-03

### Added
- Added code to update DNS resolution

## [0.5.3] - 2024-09-03

### Added
- Added code to set shell for user

## [0.5.2] - 2024-09-03

### Added
- Added code to generate SSH server keys

## [0.5.1] - 2024-09-03

### Fixed
- Fixed network/netplan config creation

## [0.5.0] - 2024-09-03

### Fixed
- Fixed bugs and updated documentation

## [0.4.9] - 2024-09-03

### Fixed
- Fixed bugs and updated documentation

## [0.4.8] - 2024-09-03

### Added
- Added ability to perform multiple actions in one command line

## [0.4.7] - 2024-09-02

### Fixed
- Fixed permissions and updated documentation

## [0.4.6] - 2024-09-02

### Changed
- Updated documentation

## [0.4.5] - 2024-09-02

### Changed
- Code cleanup

## [0.4.4] - 2024-09-02

### Added
- Added code to update sudoers

## [0.4.3] - 2024-09-01

### Added
- Added code to create users and groups

## [0.4.2] - 2024-09-01

### Added
- Added code to install packages

## [0.4.1] - 2024-09-01

### Added
- Added code to set hostname

## [0.4.0] - 2024-09-01

### Added
- Added VM check to network configuration

## [0.3.9] - 2024-08-31

### Changed
- More formatting fixes

## [0.3.8] - 2024-08-31

### Changed
- Formatting fixes

## [0.3.7] - 2024-08-31

### Added
- Added code to print contents of file

## [0.3.6] - 2024-08-31

### Added
- Added code to create netplan file

## [0.3.5] - 2024-08-30

### Changed
- Improvements

## [0.3.4] - 2024-08-30

### Fixed
- Bug fixes

## [0.3.3] - 2024-08-30

### Added
- Added bridge check

## [0.3.2] - 2024-08-30

### Changed
- Update for permissions check

## [0.3.1] - 2024-08-29

### Fixed
- Fixed network switch for virt-install

## [0.3.0] - 2024-08-29

### Fixed
- Fixed bug with disk creation

## [0.2.9] - 2024-08-29

### Fixed
- Fixed network switch for virt-install

## [0.2.8] - 2024-08-28

### Fixed
- Fixed code to get image

## [0.2.7] - 2024-08-28

### Added
- Added support to change image password

## [0.2.6] - 2024-08-28

### Added
- Added support to run command in image

## [0.2.5] - 2024-08-28

### Added
- Added upload function

## [0.2.4] - 2024-08-28

### Added
- Added initial code to inject SSH file into image

### Fixed
- Fixed list actions

## [0.2.3] - 2024-08-26

### Fixed
- Fixed bugs

## [0.2.2] - 2024-08-26

### Added
- Initial support for post install config

## [0.2.1] - 2024-08-25

### Added
- Added code to connect/console to VM

## [0.2.0] - 2024-08-25

### Added
- Added code to delete VM

## [0.1.9] - 2024-08-24

### Fixed
- Bug fixes and added os-variant

## [0.1.8] - 2024-08-24

### Added
- Added check for virt-manager cache directory

## [0.1.7] - 2024-08-24

### Fixed
- Fixed code to delete pool

## [0.1.6] - 2024-08-24

### Added
- Added code to stop/start VM

## [0.1.5] - 2024-08-24

### Added
- Added deletepool function

## [0.1.4] - 2024-08-23

### Added
- Added initial code for creating VMs

## [0.1.3] - 2024-08-23

### Fixed
- Fixed image filename determination

## [0.1.2] - 2024-08-23

### Changed
- Moved help greps into functions to speed general startup

## [0.1.1] - 2024-08-23

### Added
- Added notice message

## [0.1.0] - 2024-08-22

### Added
- Added shellcheck code and switch

## [0.0.9] - 2024-08-22

### Changed
- Improved options and help processing

## [0.0.8] - 2024-08-22

### Changed
- Improved action processing

## [0.0.7] - 2024-08-22

### Fixed
- Fixed actions processing

## [0.0.6] - 2024-08-22

### Added
- Added action switch and documentation

## [0.0.5] - 2024-08-22

### Fixed
- Fixed code to create pools

## [0.0.4] - 2024-08-22

### Added
- Added code to check parameter values

## [0.0.3] - 2024-08-22

### Fixed
- Fixed code to fetch image

## [0.0.2] - 2024-08-21

### Added
- Added code to check environment and fetch cloud image

## [0.0.1] - 2024-08-20

### Added
- Initial shell of script
