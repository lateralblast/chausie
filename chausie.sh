#!/usr/bin/env bash

# Name:         chausie (Cloud-Image Host Automation Utility and System Image Engine)
# Version:      1.0.3
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          https://github.com/lateralblast/chausie
# Distribution: Ubuntu Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script designed to simplify creation of custom Ubuntu Cloud Images

# shellcheck disable=SC2034
# shellcheck disable=SC1090
# shellcheck disable=SC2128
# shellcheck disable=SC2129
# shellcheck disable=SC2178

# Create arrays for options and actions

declare -A os
declare -A vm
declare -A cli
declare -A script
declare -A options
declare -A defaults

# Set/get some environment parameters

os['name']=$( uname )
os['arch']=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
os['user']=$( whoami )
os['home']="$HOME"
os['group']=$( id -gn )
script['args']="$*"
script['file']="$0"
script['name']="chausie"
script['file']=$( realpath "${script['file']}" )
script['path']=$( dirname "${script['file']}" )
script['bin']=$( basename "${script['file']}" )

export LIBGUESTFS_BACKEND=direct

# Print help

print_help () {
  script['help']=$( grep -A1 "# switch" "${script['file']}" |sed "s/^--//g" |sed "s/# switch//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/ /g" | sed "/^\s*$/d" )
  echo "Usage: ${script['bin']} [OPTIONS...]"
  echo "-----"
  echo "${script['help']}"
  echo ""
}

# If given no arguments print help

if [ "${script['args']}" = "" ]; then
  print_help
  exit
fi

# Print actions

print_actions () {
  script['actions']=$( grep -A1 "# action" "${script['file']}" |sed "s/^--//g" |sed "s/# action//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/ /g" |sed "/^\s*$/d" )
  echo "Actions:"
  echo "-------"
  echo "${script['actions']}"
  echo ""
}

# Print options

print_options () {
  script['options']=$( grep -A1 "# option" "${script['file']}" |sed "s/^--//g" |sed "s/# option//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/ /g" |sed "/^\s*$/d" )
  echo "Options:"
  echo "-------"
  echo "${script['options']}"
  echo ""
}

# Print Usage

print_usage () {
  usage="$1"
  case "${usage}" in
    all|full)
      print_help
      print_actions
      print_options
      ;;
    help)
      print_help
      ;;
    action*)
      print_actions
      ;;
    options)
      print_options
      ;;
    *)
      print_help
      ;;
  esac
}

# Print version

print_version () {
  script['vers']=$( grep '^# Version' < "$0" | awk '{print $3}' )
  echo "${script['vers']}"
}

# Exit routine

do_exit () {
  if [ "${options['dryrun']}" = "false" ]; then
    exit
  fi
}

# Check value

check_value () {
  param="$1"
  value="$2"
  if [[ "${value}" =~ "--" ]]; then
    warning_message "Value '${value}' for parameter '${param}' looks like a parameter"
    if [ "${options['force']}" = "false" ]; then
      do_exit
    fi
  fi
}

# Install required packages

check_packages () {
  for package in ${os['requiredpackages']}; do
    package_check=$( echo "${os['installedpackages']}" |grep -c "^${package}$" )
    if [ "${package_check}" = "0" ]; then
      if [ "${os['name']}" = "Darwin" ]; then
        execute_command "brew install ${package}"       ""
      else
        execute_command "apt-get install -y ${package}" "su"
      fi
    fi
  done
}

# Run Shellcheck

check_shellcheck () {
  bin_test=$( command -v shellcheck | grep -c shellcheck )
  if [ ! "${bin_test}" = "0" ]; then
    shellcheck "${script['file']}"
  fi
}

# Get Release from Codename

get_release_from_codename () {
  case "${vm['codename']}" in
    warty)
      vm['release']="4.10"
      ;;
    hoary)
      vm['release']="5.04"
      ;;
    breezy)
      vm['release']="5.10"
      ;;
    dapper)
      vm['release']="6.04"
      ;;
    edgy)
      vm['release']="6.10"
      ;;
    feisty)
      vm['release']="7.04"
      ;;
    gutsy)
      vm['release']="7.10"
      ;;
    hardy)
      vm['release']="8.04"
      ;;
    intrepid)
      vm['release']="8.10"
      ;;
    jaunty)
      vm['release']="9.04"
      ;;
    karmic)
      vm['release']="9.10"
      ;;
    lucid)
      vm['release']="10.04"
      ;;
    maverick)
      vm['release']="10.10"
      ;;
    natty)
      vm['release']="11.04"
      ;;
    oneiric)
      vm['release']="11.10"
      ;;
    precise)
      vm['release']="12.04"
      ;;
    quantal)
      vm['release']="12.10"
      ;;
    raring)
      vm['release']="13.04"
      ;;
    saucy)
      vm['release']="13.10"
      ;;
    trusty)
      vm['release']="14.04"
      ;;
    utopic)
      vm['release']="14.10"
      ;;
    vivid)
      vm['release']="15.04"
      ;;
    wily)
      vm['release']="15.10"
      ;;
    xenial)
      vm['release']="16.04"
      ;;
    yakkety)
      vm['release']="16.10"
      ;;
    zesty)
      vm['release']="17.04"
      ;;
    artful)
      vm['release']="17.10"
      ;;
    bionic)
      vm['release']="18.04"
      ;;
    cosmic)
      vm['release']="18.10"
      ;;
    disco)
      vm['release']="19.04"
      ;;
    eoan)
      vm['release']="19.10"
      ;;
    focal)
      vm['release']="20.04"
      ;;
    groovy)
      vm['release']="20.10"
      ;;
    hirsuite)
      vm['release']="21.04"
      ;;
    impish)
      vm['release']="21.10"
      ;;
    jammy)
      vm['release']="22.04"
      ;;
    kinetic)
      vm['release']="22.10"
      ;;
    lunar)
      vm['release']="23.04"
      ;;
    mantic)
      vm['release']="23.10"
      ;;
    noble)
      vm['release']="24.04"
      ;;
    oracular)
      vm['release']="24.10"
      ;;
    plucky)
      vm['release']="25.04"
      ;;
    questing)
      vm['release']="25.10"
      ;;
  esac
}

# Get DNS

get_dns () {
  if [ "${os['name']}" = "Darwin" ]; then
    vm['dns']=$( scutil --dns | grep nameserver |head -1 |awk '{print $3}' )
  else
    vm['dns']=$( resolvectl 2> /dev/null |grep "DNS Servers" |head -1 |awk '{print $3}' )
    if [ "${vm['dns']}" = "" ]; then
      vm['dns']=$( resolvectl 2> /dev/null |grep "Current DNS" |awk '{print $4}' )
    fi
    if [ "${vm['dns']}" = "" ]; then
      vm['dns']=$( nslookup www.google.com |grep Server |awk '{print $2}' |head -1 )
    fi
  fi
}

# Get gateway

get_gateway () {
  if [ "${os['name']}" = "Darwin" ]; then
    vm['gateway']=$( route -n get default |grep gateway |awk '{print $2}' )
  else
    vm['gateway']=$( ip r |grep default |awk '{print $3}' )
  fi
}

# Get cidr

get_cidr () {
  if [ "${os['name']}" = "Darwin" ]; then
    bin_test=$( command -v ipcalc | grep -c ipcalc )
    if [ ! "${bin_test}" = "0" ]; then
      interface=$( route -n get default |grep interface |awk '{print $2}' )
      vm['netmask']=$( ifconfig "${interface}" |grep mask |awk '{print $4}' )
      vm['cidr']=$( ipcalc "1.1.1.1" "${vm['netmask']}" | grep ^Netmask |awk '{print $4}' )
    else
      warning_message "Tool ipcalc not found"
      vm['cidr']="24"
    fi
  else
    vm['cidr']=$( ip r |grep link |grep "${vm['bridge']}" |awk '{print $1}' |cut -f2 -d/ |head -1 )
    if [[ "${vm['cidr']}" =~ . ]] || [ "${vm['cidr']}" = "" ]; then
      vm['netmask']=$( route -n |awk '{print $3}' |grep "^255" )
      vm['cidr']=$( ipcalc "1.1.1.1" "${vm['netmask']}" | grep ^Netmask |awk '{print $4}' )
    fi
  fi
}

# Check VM name

check_vm_name () {
  if [ "${vm['name']}" = "" ]; then
    information_message "VM name is not set"
    if [ ! "${vm['hostname']}" = "" ]; then
      vm['name']="${vm['hostname']}"
      information_message "Setting VM name to ${vm['name']}"
    else
      do_exit
    fi
  fi
  if [ "${vm['name']}" = "${script['name']}" ]; then
    warning_message "VM name is set to default \"${vm['name']}\""
    if [ ! "${vm['hostname']}" = "" ]; then
      vm['name']="${vm['hostname']}"
      information_message "Setting VM name to ${vm['name']}"
    else
      if [ "${options['force']}" = "false" ]; then
        do_exit
      fi
    fi
  fi
}

# Set defaults

set_defaults () {
  vm['ip']=""
  vm['ram']=""
  vm['dns']=""
  vm['arch']=""
  vm['boot']=""
  vm['cidr']=""
  vm['size']=""
  vm['release']=""
  vm['cpus']=""
  vm['name']=""
  vm['disk']=""
  vm['fqdn']=""
  vm['dhcp']="false"
  vm['lock']="false"
  vm['state']=""
  vm['gecos']=""
  vm['shell']=""
  vm['cdrom']=""
  vm['crypt']=""
  vm['power']=""
  vm['exists']="false"
  vm['domain']=""
  vm['userid']=""
  vm['sshkey']=""
  vm['netbus']=""
  vm['netdev']=""
  vm['netcfg']=""
  vm['bridge']=""
  vm['kernel']="linux-generic"
  vm['runcmd']="/usr/bin/systemctl set-default multi-user.target"
  vm['machine']=""
  vm['sudoers']=""
  vm['netmask']=""
  vm['homedir']=""
  vm['cputype']=""
  vm['gateway']=""
  vm['initcfg']=""
  vm['nettype']=""
  vm['pooldir']=""
  vm['groupid']=""
  vm['virtdir']=""
  vm['packages']=""
  vm['hostname']=""
  vm['username']=""
  vm['password']=""
  vm['codename']=""
  vm['graphics']=""
  vm['imagedir']=""
  vm['imageurl']=""
  vm['poolname']=""
  vm['destfile']=""
  vm['cachedir']=""
  vm['imagedir']=""
  vm['fileperms']=""
  vm['fileowner']=""
  vm['filegroup']=""
  vm['osvariant']=""
  vm['imagename']=""
  vm['imagefile']=""
  vm['groupname']=""
  vm['postscript']=""
  vm['sourcefile']=""
  vm['hostdevice']=""
  vm['releasedir']=""
  vm['sshkeyfile']=""
  os['libvirtgroups']="kvm libvirt libvirt-qemu"
  options['hwe']="false"
  options['mask']="false"
  options['debug']="false"
  options['force']="false"
  options['strict']="false"
  options['dryrun']="false"
  options['reboot']="false"
  options['localds']="true"
  options['actions']="false"
  options['options']="false"
  options['verbose']="false"
  options['backing']="true"
  options['autostart']="false"
  options['shellcheck']="false"
  options['secureboot']="false"
  options['autoconsole']="false"
  options['passthrough']="false"
  defaults['ram']="4096"
  defaults['cpus']="2"
  defaults['size']="20G"
  defaults['boot']="uefi"
  defaults['power']="reboot"
  defaults['shell']="/bin/bash"
  defaults['groups']="users"
  defaults['userid']="1000"
  defaults['netdev']="enp1s0"
  defaults['netbus']="virtio"
  defaults['release']="24.04"
  defaults['nettype']="bridge"
  defaults['groupid']="1000"
  defaults['sudoers']="ALL=(ALL) NOPASSWD:ALL"
  defaults['features']=""
  defaults['graphics']="none"
  defaults['packages']="ansible"
  defaults['username']="cloudadmin"
  defaults['password']="cloudadmin"
  if [ "${os['name']}" = "Darwin" ]; then
    os['installedpackages']=$( brew list )
    os['requiredpackages']="qemu libvirt libvirt-glib libvirt-python virt-manager libosinfo ipcalc cdrtools"
    defaults['bridge']="en0"
  else
    os['installedpackages']=$( dpkg -l |grep ^ii |awk '{print $2}' )
    os['requiredpackages']="virt-manager libosinfo-bin libguestfs-tools cloud-image-utils ipcalc whois"
    defaults['bridge']="br0"
  fi
  if [ "${os['name']}" = "Darwin" ]; then
    if [ "${os['arch']}" = "arm64" ]; then
      defaults['cputype']="cortex-a57"
    else
      defaults['cputype']="host-model"
    fi
  else
    defaults['cputype']="host-model"
  fi
}

# Verbose message

verbose_message () {
  message="$1"
  format="$2"
  if [ "${options['verbose']}" = "true" ] || [[ "${format}" =~ verbose ]]; then
    case "${format}" in
      exec*)
        echo "Executing:    ${message}"
        ;;
      info*)
        echo "Information:  ${message}"
        ;;
      not*)
        echo "Notice:       ${message}"
        ;;
      verbose)
        echo               "${message}"
        ;;
      warn*)
        echo "Warning:      ${message}"
        ;;
      *)
        echo "${message}"
        ;;
    esac
  fi
}

# Warning message

warning_message () {
  message="$1"
  verbose_message "${message}" "warn-verbose"
}

# Notice message

notice_message () {
  message="$1"
  verbose_message "${message}" "notice"
}

# Information Message

information_message () {
  message="$1"
  verbose_message "${message}" "info"
}

# Execute command

execute_command () {
  command="$1"
  privilege="$2"
  if [ "${privilege}" = "su" ]; then
    command="sudo sh -c '${command}'"
  fi
  if [ "${privilege}" = "linuxsu" ] || [ "${privilege}" = "sulinux" ]; then
    if [ "${os['name']}" = "Linux" ]; then
      command="sudo sh -c \"${command}\""
    fi
  fi
  if [ "${options['verbose']}" = "true" ]; then
    verbose_message "${command}" "execute"
  fi
  if [ "${options['dryrun']}" = "false" ]; then
    eval "${command}"
  fi
}

# Check config

check_config () {
  information_message "Checking config"
  for check_dir in "${vm['virtdir']}" "${vm['imagedir']}" "${vm['cachedir']}"; do
    information_message "Checking directory \"${check_dir}\" exists"
    if [ ! -d "${check_dir}" ]; then
      notice_message  "Creating directory \"${check_dir}\""
      execute_command "mkdir -p ${check_dir}" "linuxsu"
    fi
  done
  if [ "${os['name']}" = "Linux" ]; then
    information_message "Checking group permissions on \"/dev/kvm\""
    group_check=$( sudo stat -c "%G" "/dev/kvm" )
    if [ ! "${group_check}" = "kvm" ]; then
      notice_message  "Fixing group permissions on \"/dev/kvm\""
      execute_command "chown root:kvm /dev/kvm" "su"
    fi
    information_message "Checking permissions on \"${vm['imagedir']}\""
    perms_check=$( sudo stat -c "%a" "${vm['imagedir']}" )
    if [ ! "$perms_check" = "775" ]; then
      notice_message  "Fixing permissions on \"${vm['imagedir']}\""
      execute_command "chmod -R 775 ${vm['imagedir']}" "su"
    fi
    for group in ${os['libvirtgroups']}; do
      information_message "Checking user \"${os['user']}\" is a member of a group \"${group}\""
      group_check=$( groups |grep -c "${group}" )
      if [ "${group_check}" = "0" ]; then
        notice_message  "Adding user \"${os['user']}\" to group \"${group}\""
        execute_command "usermod -a -G ${group} ${os['user']}" "su"
      fi
    done
  fi
  check_packages
  if [ "${os['name']}" = "Darwin" ]; then
    localds_bin="/usr/local/bin/cloud-localds"
    localds_url="https://raw.githubusercontent.com/canonical/cloud-utils/main/bin/cloud-localds"
    if [ ! -f "${localds_bin}" ]; then
      execute_command "curl -o ${localds_bin} ${localds_url}" "su"
      execute_command "chmod +x ${localds_bin}"               "su"
    fi
  fi
}

# Fix Linux libvirt perms

fix_libvirt_perms () {
  file_name="$1"
  if [ "${os['name']}" = "Linux" ]; then
    execute_command "chown root:libvirt-qemu ${file_name}"    "su"
    execute_command "chmod 775 ${file_name}"                  "su"
  fi
}

# Create libvirt dir

create_libvirt_dir () {
  new_dir="$1"
  if [ ! -d "${new_dir}" ]; then
    execute_command "mkdir -p ${new_dir}" "linuxsu"
    fix_libvirt_perms "${new_dir}"
  else
    verbose_message "Directory \"${new_dir}\" already exists" "notice"
  fi
}

# Delete libvirt dir

delete_libvirt_dir () {
  new_dir="$1"
  if [ -d "${new_dir}" ] && [ "${new_dir}" != "/" ]; then
    execute_command "rm -rf ${new_dir}" "linuxsu"
  else
    verbose_message "Directory \"${new_dir}\" does not exist" "notice"
  fi
}

# Get image

get_image () {
  if [ "${vm['releasedir']}" = "" ]; then
    vm['releasedir']="${vm['imagedir']}/releases"
  fi
  create_libvirt_dir "${vm['releasedir']}"
  if [ ! -f "${vm['releasedir']}/${vm['imagefile']}" ]; then
    execute_command "cd ${vm['releasedir']} ; wget ${vm['imageurl']}" "linuxsu"
  else
    verbose_message "Cloud Image \"${vm['releasedir']}/${vm['imagefile']}\" already exists" "notice"
  fi
}

# Create Pool

create_pool () {
  create_libvirt_dir "${vm['pooldir']}"
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ ! "$pool_test" =~ ${vm['poolname']} ]]; then
    execute_command "virsh pool-create-as --name ${vm['poolname']} --type dir --target ${vm['pooldir']} > /dev/null 2>&1" ""
    fix_libvirt_perms "${vm['pooldir']}"

  else
    verbose_message "Pool \"${vm['poolname']}\" already exists" "notice"
  fi
}

# Delete Pool

delete_pool () {
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ "$pool_test" =~ ${vm['poolname']} ]]; then
    execute_command "virsh pool-destroy --pool ${vm['poolname']} > /dev/null 2>&1" ""
  else
    verbose_message "Pool \"${vm['poolname']}\" does not exist" "notice"
  fi
  delete_libvirt_dir "${vm['pooldir']}"
}

# Check VM bridge

check_bridge () {
  if [ "${os['name']}" = "Linux" ]; then
    bridge_check=$( ip link show "${vm['bridge']}" 2>&1 |grep "does not exist" |wc -c )
    if [ ! "$bridge_check" = "0" ]; then
      warning_message "Bridge device \"${vm['bridge']}\" does not exist"
      do_exit
    fi
  fi
}

# Check Cloud Image exists

check_image_exists () {
  if [ ! -f "${vm['releasedir']}/${vm['imagefile']}" ]; then
    warning_message "Cloud Image file \"${vm['releasedir']}/${vm['imagefile']}\" does not exist"
    do_exit
  else
    information_message "Found Cloud Image file \"${vm['releasedir']}/${vm['imagefile']}\""
  fi
}

# Create VM disk

create_disk () {
  if [ -f "${vm['disk']}" ]; then
    warning_message "VM disk file \"${vm['disk']}\" already exists"
  else
    if [ "${options['backing']}" = "true" ]; then
      execute_command "qemu-img create -b ${vm['releasedir']}/${vm['imagefile']} -F qcow2 -f qcow2 ${vm['disk']} ${vm['size']}" "linuxsu"
    else
      execute_command "cp ${vm['releasedir']}/${vm['imagefile']} ${vm['disk']}"  "linuxsu"
      execute_command "qemu-img resize ${vm['disk']} ${vm['size']}"              "linuxsu"
    fi 
  fi
}

# Create VM

create_vm () {
  check_vm_exists
  check_bridge
  check_image_exists
  create_disk
  fix_libvirt_perms "${vm['disk']}"
  if [ "${vm['exists']}" = "false" ]; then
    if [ "${options['localds']}" = "true" ]; then
      configure_network
      configure_init
      if [ "${os['name']}" = "Linux" ]; then
        execute_command "cloud-localds --network-config ${vm['netcfg']} ${vm['cdrom']} ${vm['initcfg']}" "linuxsu"
      else
        execute_command "mkisofs -output ${vm['cdrom']} -volid cidata -joliet -rock {${vm['initcfg']},${vm['netcfg']}"
      fi
    fi
    if [ "${options['autoconsole']}" = "false" ]; then
      cli['autoconsole']="--noautoconsole"
    else
      cli['autoconsole']="--autoconsole ${vm['graphics']}"
    fi
    if [ "${options['autostart']}" = "false" ]; then
      cli['autostart']=""
    else
      cli['autostart']="--autostart"
    fi
    cli['name']="--name ${vm['name']}"
    cli['memory']="--memory ${vm['ram']}"
    cli['vcpus']="--vcpus ${vm['cpus']}"
    cli['cputype']="--cpu ${vm['cputype']}"
    if [ "${options['localds']}" = "true" ]; then
      cli['disk']="--disk ${vm['disk']},format=qcow2,bus=virtio --disk ${vm['cdrom']},device=cdrom"
    else
      cli['disk']="--disk ${vm['disk']},format=qcow2,bus=virtio"
    fi
    if [ "${os['name']}" = "Darwin" ]; then
      cli['network']=""
    else
      cli['network']="--network ${vm['nettype']}=${vm['bridge']},model=virtio"
    fi
    cli['osvariant']="--os-variant ${vm['osvariant']}"
    if [ "${vm['hostdevice']}" = "" ]; then
      cli['hostdevice']=""
    else
      cli['hostdevice']="--host-device ${vm['hostdevice']}"
    fi
    if [ "${vm['features']}" = "" ]; then
      cli['features']=""
    else
      cli['features']="--features ${vm['features']}"
    fi
    cli['graphics']="--graphics ${vm['graphics']}"
    cli['boot']="--boot ${vm['boot']}"
    if [ "${options['reboot']}" = "false" ]; then
      cli['reboot']="--noreboot"
    fi
    command="virt-install --import ${cli['name']} ${cli['memory']} ${cli['vcpus']} ${cli['cputype']} ${cli['disk']} ${cli['network']} ${cli['osvariant']} ${cli['autoconsole']} ${cli['graphics']} ${cli['boot']} ${cli['autostart']} ${cli['reboot']} ${cli['hostdevice']} ${cli['features']}"
    execute_command "${command}" "linuxsu"
    if [ "${options['localds']}" = "false" ]; then
      create_keys
    fi
  fi
}

# Check VM state

check_vm_state () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${os['name']}" = "Linux" ]; then
      vm['state']=$( sudo virsh list --all |grep " ${vm['name']} " |awk '{ print $3 }' )
    else
      vm['state']=$( virsh list --all |grep " ${vm['name']} " |awk '{ print $3 }' )
    fi
  fi
}

# Check VM exists

check_vm_exists () {
  check_vm_name
  information_message "Checking if VM \"${vm['name']}\" exists"
  if [ "${os['name']}" = "Linux" ]; then
    vm_check=$( sudo virsh list --all |grep -c " ${vm['name']} " )
  else
    vm_check=$( virsh list --all |grep -c " ${vm['name']} " )
  fi
  if [ "${vm_check}" -ne 0 ]; then
    vm['exists']="true"
  else
    vm['exists']="false"
    warning_message "VM \"${vm['name']}\" does not exist"
  fi
}

# Delete VM

delete_vm () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    stop_vm
    execute_command "virsh undefine --nvram ${vm['name']} > /dev/null 2>&1" "linuxsu"
  fi
}

# Start VM

start_vm () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    if [ ! "${vm[state]}" = "running" ]; then
      command="virsh start ${vm['name']}"
      execute_command "${command}" "linuxsu"
    fi
  fi
}

# Suspend VM

suspend_vm () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${vm[state]}" = "running" ]; then
      command="virsh suspend ${vm['name']}"
      execute_command "${command}" "linuxsu"
    fi
  fi
}

# Resume VM

resume_vm () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${vm[state]}" = "paused" ]; then
      command="virsh resume ${vm['name']}"
      execute_command "${command}" "linuxsu"
    fi
  fi
}

# Stop VM

stop_vm () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${vm[state]}" = "running" ]; then
      command="virsh shutdown ${vm['name']}"
      execute_command "${command}" "linuxsu"
    fi
  fi
}

# Connect to VM

connect_to_vm () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${vm[state]}" = "running" ]; then
      reset
      command="virsh console ${vm['name']}"
      execute_command "${command}" "linuxsu"
    fi
  fi
}

# SSH to vm

ssh_to_vm () {
  if [ "${vm['ip']}" = "" ]; then
    warning_message "No IP given to SSH to"
    do_exit
  else
    check_vm_state
    if [ "${vm[state]}" = "running" ]; then
      execute_command "ssh -oStrictHostKeyChecking=no ${vm['username']}@${vm['ip']}"
    fi
  fi
}

# Inject SSH key

inject_key () {
  check_vm_state
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${vm[state]}" = "running" ]; then
      stop_vm
    fi
    if [ -f "${vm['sshkeyfile']}" ]; then
      if [ -f "${vm['disk']}" ] || [ "${options['dryrun']}" = "true" ]; then
        execute_command "virt-customize -a ${vm['disk']} --ssh-inject ${vm['username']}:file:${vm['sshkeyfile']}" "linuxsu"
      else
        warning_message "VM disk \"${vm['disk']}\" does not exist"
      fi
    else
      warning_message "Key file \"${vm['sshkeyfile'}\" does not exist"
    fi
  fi
}

# List snapshots

list_snapshots () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ]; then
    execute_command "virsh snapshot-list ${vm['name']}" "linuxsu"
  fi

}

# Create snaphot

create_snapshot () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ]; then
    if [ "${vm['snapshot']}" = "" ] || [ "${vm['description']}" = "" ]; then
      datestr=$( date )
      suffix=$( date -d "${datestr}" +%Y%M%d%H%M%S )
      if [ "${vm['snapshot']}" = "" ]; then
        vm['snapshot']="${vm['name']}_snap_${suffix}"
      fi
      if [ "${vm['description']}" = "" ]; then
        vm['description']="Snapshot ${suffix}"
      fi
    fi
    if [ "${vm['exists']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
      execute_command "virsh snapshot-create-as --domain ${vm['name']} --name \"${vm['snapshot']}\" --description \"${vm['description']}\"" "linuxsu"
    fi
  fi
}

# Restore snapshot

restore_snapshot () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ]; then
    execute_command "virsh snapshot-revert ${vm['name']} \"${vm['snapshot']}\"" "linuxsu" 
  fi
}

# Delete snapshot

delete_snapshot () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ]; then
    execute_command "virsh snapshot-delete ${vm['name']} \"${vm['snapshot']}\"" "linuxsu" 
  fi
}

# Upload file

upload_file () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
    if [ -f "${vm['sourcefile']}" ]; then
      if [ -f "${vm['disk']}" ] || [ "${options['dryrun']}" = "true" ]; then
        execute_command "virt-customize -a ${vm['disk']} --upload ${vm['sourcefile']}:${vm['destfile']}" "linuxsu"
        if [ ! "${vm['fileowner']}" = "" ]; then
          if [ ! "${vm['filegroup']}" = "" ]; then
            command="chown ${vm['fileowner']} ${vm['destfile']}"
          else
            command="chown ${vm['fileowner']}:${vm['filegroup']} ${vm['destfile']}"
          fi
          run_command "${command}"
        fi
        if [ ! "${vm['fileperms']}" = "" ]; then
          command="chmod ${vm['fileperms']} ${vm['destfile']}"
          run_command "${command}"
        fi
      else
        warning_message "VM disk \"${vm['disk']}\" does not exist"
      fi
    else
      warning_message "Source file \"${vm['sourcefile']}\" does not exist"
    fi
  fi
}

# Run command

run_command () {
  command="$1"
  check_vm_state
  if [ "${vm['exists']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
    if [ -f "${vm['disk']}" ] || [ "${options['dryrun']}" = "true" ]; then
      if [ "${vm[state]}" = "running" ]; then
        stop_vm
      fi
      execute_command "virt-customize -a ${vm['disk']} --run-command \"${command}\"" "linuxsu"
    else
      warning_message "VM disk \"${vm['disk']}\" does not exist"
    fi
  fi
}

# Set password

set_password () {
  execute_command "virt-customize -a ${vm['disk']} --root-password password:${vm['password']}"
}

# Customize VM

customize_vm () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
    stop_vm
    if [ -f "${vm['postscript']}" ] || [ "${options['dryrun']}" = "true" ]; then
      execute_command "virt-customize " "linuxsu"
    else
      warning_message "Post install script \"${vm['postscript']}\" does not exist"
    fi
  fi
}

# Print contents of file

print_contents () {
  file_name="$1"
  if [ -f "${file_name}" ]; then
    if [ "${options['verbose']}" = "true" ]; then
      information_message "Contents of file \"${file_name}\""
      cat "${file_name}"
    fi
  fi
}

# Generate password crypt/hash

generate_crypt () {
  if [ "${vm['crypt']}" = "" ]; then
    if [ "${os['name']}" = "Darwin" ]; then
      vm['crypt']=$( echo -n "${vm['password']}" |openssl sha512 | awk '{ print $2 }' )
    else
      vm['crypt']=$( echo "${vm['password']}" |mkpasswd --method=SHA-512 --stdin )
    fi
  fi
}

# Configure cloud-init config file

configure_init () {
  temp_file="/tmp/cloud-init.cfg"
  mask_file="/tmp/cloud-init.cfg.masked"
  generate_crypt
  echo "#cloud-config"                                |tee "${mask_file}"      > "${temp_file}"
  echo "hostname: ${vm['hostname']}"                  |tee -a "${mask_file}"  >> "${temp_file}"
  echo "groups:"                                      |tee -a "${mask_file}"  >> "${temp_file}"
  echo "  - ${vm['groupname']}: ${vm['username']}"    |tee -a "${mask_file}"  >> "${temp_file}"
  echo "users:"                                       |tee -a "${mask_file}"  >> "${temp_file}"
  echo "  - default"                                  |tee -a "${mask_file}"  >> "${temp_file}"
  echo "  - name: ${vm['username']}"                  |tee -a "${mask_file}"  >> "${temp_file}"
  echo "    gecos: ${vm['gecos']}"                    |tee -a "${mask_file}"  >> "${temp_file}"
  echo "    primary_group: ${vm['groupname']}"        |tee -a "${mask_file}"  >> "${temp_file}"
  echo "    groups: ${vm['groups']}"                  |tee -a "${mask_file}"  >> "${temp_file}"
  echo "    shell: ${vm['shell']}"                    |tee -a "${mask_file}"  >> "${temp_file}"
  echo "    passwd: \"#MASKED#\""                                             >> "${mask_file}"
  echo "    passwd: \"${vm['crypt']}\""                                       >> "${temp_file}"
  if [ ! "${vm['sshkey']}" = "" ]; then
    echo "    ssh_authorized_keys:"                   |tee -a "${mask_file}"  >> "${temp_file}"
    echo "      - \"#MASKED#\""                                               >> "${mask_file}"
    echo "      - \"${vm['sshkey']}\""                                        >> "${temp_file}"
  fi
  echo "    sudo: ${vm['sudoers']}"                   |tee -a "${mask_file}"  >> "${temp_file}"
  echo "    lock_passwd: ${vm['lock']}"               |tee -a "${mask_file}"  >> "${temp_file}"
  echo "packages:"                                    |tee -a "${mask_file}"  >> "${temp_file}"
  if [[ "${vm['packages']}" =~ "," ]]; then
    IFS="," read -r -a array <<< "${vm['packages']}"
    for vm_package in "${array[@]}"; do
      echo "  - ${vm_package}"                        |tee -a "${mask_file}"  >> "${temp_file}"
    done
  else
    echo "  - ${vm['packages']}"                      |tee -a "${mask_file}"  >> "${temp_file}"
  fi
  echo "growpart:"                                    |tee -a "${mask_file}"  >> "${temp_file}"
  echo "  mode: auto"                                 |tee -a "${mask_file}"  >> "${temp_file}"
  echo "  devices: ['/']"                             |tee -a "${mask_file}"  >> "${temp_file}"
  echo "power_state:"                                 |tee -a "${mask_file}"  >> "${temp_file}"
  echo "  mode: ${vm['power']}"                       |tee -a "${mask_file}"  >> "${temp_file}"
  if [ ! "${vm['runcmd']}" = "" ]; then
    echo "runcmd:"                                    |tee -a "${mask_file}"  >> "${temp_file}"
    echo "  - [ sh, \"${vm['runcmd']}\" ]"            |tee -a "${mask_file}"  >> "${temp_file}"
  fi
  if [ "${options['mask']}" = "true" ]; then
    print_contents "${mask_file}"
  else
    print_contents "${temp_file}"
  fi
  execute_command "cp ${temp_file} ${vm['initcfg']}" "linuxsu"
}

# Configure network

configure_network () {
  check_vm_exists
  temp_file="/tmp/01-netcfg.yaml"
  if [ "${options['localds']}" = "false" ]; then
    if [ "${vm['exists']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
      stop_vm
      echo "network:"                                    > "${temp_file}"
      echo "  ethernets:"                               >> "${temp_file}"
      echo "    ${vm['netdev']}:"                       >> "${temp_file}"
      echo "      dhcp4: ${vm['dhcp']}"                 >> "${temp_file}"
      if [ "${vm['dhcp']}" = "false" ]; then
        echo "      addresses:"                     
        if [[ "${vm['ip']}" =~ "," ]]; then
          IFS="," read -r -a array <<< "${vm['ip']}"
          for vm_ip in "${array[@]}"; do
            echo "        - ${vm_ip}/${vm['cidr']}"     >> "${temp_file}"
          done
        else
          echo "        - ${vm['ip']}/${vm['cidr']}"    >> "${temp_file}"
        fi
        echo "      nameservers:"                       >> "${temp_file}"
        echo "        addresses:"                       >> "${temp_file}"
        if [[ "${vm['dns']}" =~ "," ]]; then
          IFS="," read -r -a array <<< "${vm['dns']}"
          for vm_dns in "${array[@]}"; do
            echo "          - ${vm_dns}"                >> "${temp_file}"
          done
        else
          echo "          - ${vm['dns']}"               >> "${temp_file}"
        fi
        if [ "${vm['majorrelease']}" -gt 22 ]; then
          echo "      routes:"                          >> "${temp_file}"
          echo "        - to: default"                  >> "${temp_file}"
          echo "          via: ${vm['gateway']}"        >> "${temp_file}"
        else
          echo "      gateway4: ${vm['gateway']}"       >> "${temp_file}"
        fi
      fi
      echo "  version: 2"                               >> "${temp_file}"
      vm['sourcefile']="${temp_file}"
      chmod 700 "${vm['sourcefile']}"
      print_contents "${vm['sourcefile']}"
      vm['destfile']="/etc/netplan/01-netcfg.yaml"
      vm['fileperms']="600"
      vm['fileowner']="root"
      upload_file
      command="sed -i \"s/#DNS=/DNS=${vm['dns']}/g\" /etc/systemd/resolved.conf"
      run_command "${command}"
      command="rm /etc/resolv.conf"
      run_command "${command}"
      command="echo \"nameserver ${vm['dns']}\" > /etc/resolv.conf"
      run_command "${command}"
    else
      warning_message "VM \"${vm['name']}\" does not exist"
    fi
  else
    echo "ethernets:"                                    > "${temp_file}"
    echo "  ${vm['netdev']}:"                           >> "${temp_file}"
    echo "    dhcp4: ${vm['dhcp']}"                     >> "${temp_file}"
    if [ "${vm['dhcp']}" = "false" ]; then
      echo "    addresses:"                             >> "${temp_file}"
      if [[ "${vm['ip']}" =~ "," ]]; then
        IFS="," read -r -a array <<< "${vm['ip']}"
        for vm_ip in "${array[@]}"; do
          echo "      - ${vm_ip}/${vm['cidr']}"         >> "${temp_file}"
        done
      else
        echo "      - ${vm['ip']}/${vm['cidr']}"        >> "${temp_file}"
      fi
      echo "    nameservers:"                           >> "${temp_file}"
      echo "      addresses:"                           >> "${temp_file}"
      if [[ "${vm['dns']}" =~ "," ]]; then
        IFS="," read -r -a array <<< "${vm['dns']}"
        for vm_dns in "${array[@]}"; do
          echo "        - ${vm_dns}"                    >> "${temp_file}"
        done
      else
        echo "        - ${vm['dns']}"                   >> "${temp_file}"
      fi
      if [ "${vm['majorrelease']}" -gt 22 ]; then
        echo "    routes:"                              >> "${temp_file}"
        echo "      - to: default"                      >> "${temp_file}"
        echo "        via: ${vm['gateway']}"            >> "${temp_file}"
      else
        echo "    gateway4: ${vm['gateway']}"           >> "${temp_file}"
      fi
    fi
    echo "version: 2"                                   >> "${temp_file}"
    vm['sourcefile']="${temp_file}"
    chmod 700 "${vm['sourcefile']}"
    print_contents "${vm['sourcefile']}"
    execute_command "cp ${vm['sourcefile']} ${vm['netcfg']}" "linuxsu"
  fi
}

# Set VM hostname

set_hostname () {
  if [ "${vm['fqdn']}" = "" ]; then
    if [ "${vm['domain']}" = "" ]; then
      vm['fqdn']="${vm['hostname']}"
    else
      vm['fqdn']="${vm['hostname']}.${vm['domain']}"
    fi
  fi
  command="hostnamectl set-hostname ${vm['fqdn']}"
  run_command "${command}"
}

install_packages () {
  check_vm_exists
  if [ "${vm['exists']}" = "true" ] || [ "${options['dryrun']}" = "true" ]; then
    if [ -f "${vm['disk']}" ] || [ "${options['dryrun']}" = "true" ]; then
      execute_command "virt-customize -a ${vm['disk']} --install \"${vm['packages']}\"" "linuxsu"
    else
      warning_message "VM disk \"${vm['disk']}\" does not exist"
    fi
  else
    warning_message "VM \"${vm['name']}\" does not exist"
  fi
}

add_group () {
  if [ "${vm['groupid']}" = "" ]; then
    command="groupadd ${vm['groupname']}"
  else
    command="groupadd -g ${vm['groupid']} ${vm['groupname']}"
  fi
  run_command "${command}"
}

add_user () {
  add_group
  if [ "${vm['userid']}" = "" ]; then
    command="useradd -g ${vm['groupname']} -s ${vm['shell']} -m -d ${vm['homedir']} ${vm['username']}"
  else
    command="useradd -u ${vm['userid']} -g ${vm['groupname']} -s ${vm['shell']} -m -d ${vm['homedir']} ${vm['username']}"
  fi
  run_command "${command}"
}

add_sudoers () {
  if [ "${vm['sourcefile']}" = "" ]; then
    vm['sourcefile']="/tmp/sudoers.${vm['username']}"
    echo "${vm['username']} ${vm['sudoers']}" > "${vm['sourcefile']}"
  fi
  if [ "${vm['destfile']}" = "" ]; then
    vm['destfile']="/etc/sudoers.d/${vm['username']}"
  fi
  vm['fileowner']="root"
  vm['filegroup']="root"
  vm['fileperms']="600"
  print_contents "${vm['sourcefile']}"
  upload_file
}

# Create SSH server keys

create_keys () {
  stop_vm
  command="ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -t ed25519  -N \"\""
  run_command "${command}"
}

# List VMs

list_vms () {
  execute_command "virsh list --all" "linuxsu"
}

# List Pools

list_pools () {
  execute_command "virsh pool-list --all" "linuxsu"
}

# List Nets

list_nets () {
  execute_command "virsh net-list --all" "linuxsu"
}

# Reset defaults

reset_defaults () {
  if [ "${options['debug']}" = "true" ]; then
    set -x
  fi
  verbose_message "Enabling debug mode"                 "notice"
  if [ "${options['strict']}" = "true" ]; then
    set -u
  fi
  verbose_message "Enabling strict mode"                "notice"
  if [ "${options['dryrun']}" = "true" ]; then
    verbose_message "Enabling dryrun mode"              "notice"
  fi
  if [ "${vm['arch']}" = "" ]; then
    vm['arch']="${os['arch']}"
  fi
  verbose_message "Setting arch to \"${vm['arch']}\""   "notice"
  if [ "${vm['cputype']}" = "" ]; then
    vm['cputype']="${defaults['cputype']}"
  fi
  verbose_message "Setting CPU type to \"${vm['cputype']}\""     "notice"
  if [ "${vm['name']}" = "" ]; then
    vm['name']="${script['name']}"
  fi
  verbose_message "Setting VM name to \"${vm['name']}\""         "notice"
  if [ "${vm['cpus']}" = "" ]; then
    vm['cpus']="${defaults['cpus']}"
  fi
  verbose_message "Setting VM CPUs to \"${vm['cpus']}\""         "notice"
  if [ "${vm['ram']}" = "" ]; then
    vm['ram']="${defaults['ram']}"
  fi
  verbose_message "Setting VM RAM to \"${vm['ram']}\""           "notice"
  if [ "${vm['size']}" = "" ]; then
    vm['size']="${defaults['size']}"
  fi
  verbose_message "Setting VM size to \"${vm['size']}\""         "notice"
  if [ "${vm['release']}" = "" ]; then
    if [ "${vm['codename']}" = "" ]; then
      vm['release']="${defaults['release']}"
    else
      get_release_from_codename
    fi
  fi
  verbose_message "Setting OS version to \"${vm['release']}\""   "notice"
  if [ "${vm['boot']}" = "" ]; then
    vm['boot']="${defaults['boot']}"
  fi
  verbose_message "Setting boot type to \"${vm['boot']}\""    "notice"
  if [ "${vm['graphics']}" = "" ]; then
    vm['graphics']="${defaults['graphics']}"
  fi
  verbose_message "Setting graphics to \"${vm['graphics']}\"" "notice"
  if [ "${vm['hostname']}" = "" ]; then
    vm['hostname']="${vm['name']}"
  fi
  verbose_message "Setting hostname to \"${vm['hostname']}\"" "notice"
  if [ "${vm['nettype']}" = "" ]; then
    vm['nettype']="${defaults['nettype']}"
  fi
  verbose_message "Setting net type to \"${vm['nettype']}\""  "notice"
  if [ "${vm['bridge']}" = "" ]; then
    vm['bridge']="${defaults['bridge']}"
  fi
  verbose_message "Setting bridge to \"${vm['bridge']}\""           "notice"
  if [ "${vm['netbus']}" = "" ]; then
    vm['netbus']="${defaults['netbus']}"
  fi
  verbose_message "Setting net bus to \"${vm['netbus']}\""          "notice"
  if [ "${vm['netdev']}" = "" ]; then
    vm['netdev']="${defaults['netdev']}"
  fi
  verbose_message "Setting net device to \"${vm['netdev']}\""       "notice"
  if [ "${vm['gateway']}" = "" ]; then
    get_gateway
  fi
  verbose_message "Setting gateway to \"${vm['gateway']}\""         "notice"
  if [ "${vm['cidr']}" = "" ]; then
    get_cidr
  fi
  verbose_message "Setting CIDR to \"${vm['cidr']}\""               "notice"
  if [ "${vm['dns']}" = "" ]; then
    get_dns
  fi
  verbose_message "Setting DNS server to \"${vm['dns']}\""          "notice"
  if [ ! "${vm['hostdevice']}" = "" ]; then
    vm['features']="${defaults['features']}"
    verbose_message "Setting features to \"${vm['features']}\""     "notice"
  fi
  if [ ! "${vm['machine']}" = "" ]; then
    verbose_message "Setting machine to \"${vm['machine']}\""       "notice"
  fi
  if [ "${vm['imagefile']}" = "" ]; then
    vm['imagefile']="ubuntu-${vm['release']}-server-cloudimg-${os['arch']}.img"
  fi
  verbose_message "Setting Cloud Image to \"${vm['imagefile']}\""   "notice"
  if [ "${vm['imageurl']}" = "" ]; then
    vm['imageurl']="https://cloud-images.ubuntu.com/releases/${vm['release']}/release/${vm['imagefile']}"
  fi
  verbose_message "Setting CI URL to \"${vm['imageurl']}\""         "notice"
  if [ "${os['name']}" = "Darwin" ]; then
    os['brewdir']="/opt/homebrew/Cellar"
    if [ ! -d "$os['brewdir']" ]; then
      os['brewdir']="/usr/local/Cellar"
    fi
    verbose_message "Setting brew directory to \"${os['brewdir']}\""     "notice"
  fi
  if [ "${vm['virtdir']}" = "" ]; then
    if [ "${os['name']}" = "Darwin" ]; then
      vm['virtdir']="$os['brewdir']/libvirt"
    else
      vm['virtdir']="/var/lib/libvirt"
    fi
  fi
  verbose_message "Setting libvirt directory to \"${vm['virtdir']}\""     "notice"
  if [ "${vm['imagedir']}" = "" ]; then
    vm['imagedir']="${vm['virtdir']}/images"
  fi
  verbose_message "Setting Image directory to \"${vm['imagedir']}\""      "notice"
  if [ "${vm['disk']}" = "" ]; then
    vm['disk']="${vm['imagedir']}/${vm['name']}/${vm['name']}.qcow2"
  fi
  verbose_message "Setting disk to \"${vm['disk']}\""                     "notice"
  if [ "${options['localds']}" = "true" ]; then
    if [ "${vm['cdrom']}" = "" ]; then
      vm['cdrom']="${vm['imagedir']}/${vm['name']}/${vm['name']}.cloud.img"
    fi
    verbose_message "Setting cdrom to \"${vm['cdrom']}\""                 "notice"
    if [ "${vm['netcfg']}" = "" ]; then
      vm['netcfg']="${vm['imagedir']}/${vm['name']}/${vm['name']}.network.cfg"
    fi
    verbose_message "Setting net config to \"${vm['netcfg']}\""           "notice"
    if [ "${vm['initcfg']}" = "" ]; then
      vm['initcfg']="${vm['imagedir']}/${vm['name']}/${vm['name']}.cloud.cfg"
    fi
    verbose_message "Setting cloud-init to \"${vm['initcfg']}\""          "notice"
    if [ "${vm['packages']}" = "" ]; then
      vm['packages']="${defaults['packages']}"
    fi
    verbose_message "Setting packages \"${vm['initcfg']}\""               "notice"
  fi
  if [ "${vm['poolname']}" = "" ]; then
    vm['poolname']="${vm['name']}"
  fi
  verbose_message "Setting pool name to \"${vm['poolname']}\""            "notice"
  if [ "${vm['pooldir']}" = "" ]; then
    vm['pooldir']="${vm['imagedir']}/${vm['poolname']}"
  fi
  verbose_message "Setting pool directory to \"${vm['pooldir']}\""        "notice"
  if [ "${vm['releasedir']}" = "" ]; then
    vm['releasedir']="${vm['imagedir']}/releases"
  fi
  verbose_message "Setting release directory to \"${vm['releasedir']}\""  "notice"
  if [ "${vm['osvariant']}" = "" ]; then
    vm['osvariant']="ubuntu${vm['release']}"
  fi
  verbose_message "Setting OS variant to \"${vm['osvariant']}\""          "notice"
  if [ "${vm['postscript']}" = "" ]; then
    vm['postscript']="${script['path']}/scripts/post_install.sh"
  fi
  verbose_message "Setting postinstall to \"${vm['postscript']}\""        "notice"
  if [ "${vm['power']}" = "" ]; then
    vm['power']="${defaults['power']}"
  fi
  verbose_message "Setting power state to \"${vm['power']}\""             "notice"
  if [ "${vm['cachedir']}" = "" ]; then
    vm['cachedir']="${os['home']}/.cache/virt-manager"
  fi
  verbose_message "Setting cache to \"${vm['cachedir']}\""                "notice"
  if [ "${vm['username']}" = "" ]; then
    if [[ "${actions}" =~ "password" ]]; then
      vm['username']="root"
    else
      vm['username']="${defaults['username']}"
    fi
  fi
  verbose_message "Setting username to \"${vm['username']}\""   "notice"
  if [ "${vm['password']}" = "" ]; then
    vm['password']="${defaults['password']}"
  fi
  verbose_message "Setting password to \"${vm['password']}\""   "notice"
  if [ "${vm['userid']}" = "" ]; then
    vm['userid']="${defaults['userid']}"
  fi
  verbose_message "Setting user ID to \"${vm['userid']}\""      "notice"
  if [ "${vm['groupname']}" = "" ]; then
    vm['groupname']="${vm['username']}"
  fi
  verbose_message "Setting group to \"${vm['groupname']}\""     "notice"
  if [ "${vm['gecos']}" = "" ]; then
    vm['gecos']="${vm['username']}"
  fi
  verbose_message "Setting GECOS to \"${vm['gecos']}\""         "notice"
  if [ "${vm['groupid']}" = "" ]; then
    vm['groupid']="${defaults['groupid']}"
  fi
  verbose_message "Setting group ID to \"${vm['groupid']}\""    "notice"
  if [ "${vm['homedir']}" = "" ]; then
    vm['homedir']="/home/${vm['username']}"
  fi
  verbose_message "Setting home to \"${vm['homedir']}\""        "notice"
  if [ "${vm['groups']}" = "" ]; then
    vm['groups']="${defaults['groups']}"
  fi
  verbose_message "Setting groups to \"${vm['groups']}\""          "notice"
  if [ "${vm['shell']}" = "" ]; then
    vm['shell']="${defaults['shell']}"
  fi
  verbose_message "Setting shell to \"${vm['shell']}\""         "notice"
  if [ "${vm['sudoers']}" = "" ]; then
    vm['sudoers']="${defaults['sudoers']}"
  fi
  verbose_message "Setting sudoers  to \"${vm['sudoers']}\""    "notice"
  if [ "${vm['sshkeyfile']}" = "" ]; then
    vm['sshkeyfile']=$( find "${os['home']}/.ssh" -name "*.pub" |head -1 )
  fi
  verbose_message "Setting key file to \"${vm['sshkeyfile']}\"" "notice"
  if [ "${vm['sshkey']}" = "" ]; then
    if [ ! "${vm['sshkeyfile']}" = "" ]; then
      vm['sshkey']=$( cat "${vm['sshkeyfile']}" )
    fi
  fi
  verbose_message "Setting SSH key to \"${vm['sshkey']}\""      "notice"
  if [ "${vm['ip']}" = "dhcp" ] || [ "${vm['ip']}" = "" ]; then
    vm['dhcp']="true"
    verbose_message "Setting network to DHCP"                   "notice"
  else
    verbose_message "Setting network to static"                 "notice"
    verbose_message "Seting IP to \"${vm['ip']}\""              "notice"
    verbose_message "Seting CIDR to \"${vm['cidr']}\""          "notice"
    verbose_message "Seting gateway to \"${vm['gateway']}\""    "notice"
    verbose_message "Seting DNS server to \"${vm['dns']}\""     "notice"
  fi
  create_libvirt_dir "${vm['releasedir']}"
  vm['majorrelease']=$( echo "${vm['release']}" |cut -f1 -d. )
  vm['minorrelease']=$( echo "${vm['release']}" |cut -f2 -d. )
  if [[ ${vm['shell']} =~ zsh ]]; then
    vm['packages']="${vm['packages']},zsh"
  fi
  if [[ ! ${vm['shell']} =~ bin ]]; then
    if [[ ${vm['shell']} =~ zsh ]]; then
      vm['shell']="/usr/bin/${vm['shell']}"
    else
      vm['shell']="/bin/${vm['shell']}"
    fi
  fi
}

# Process action

process_actions () {
  action="$1"
  case "${action}" in
    action|help)      # action
      # Print actions help
      print_usage "actions"
      exit
      ;;
    *config)          # action
      # Check config
      check_config
      ;;
    connect|console)  # action
      # Connect to VM console
      connect_to_vm
      ;;
    copy|upload)      # action
      # Copy file into VM image
      upload_file
      ;;
    createpool)       # action
      # Create pool
      create_pool
      ;;
    snap*|backup)    # action
      # Create snapshot
      create_snapshot
      ;;
    deletesnap*)     # action
      # Delete snapshot
      delete_snapshot
      ;;
    createvm)         # action
      # Create VM
      get_image
      check_config
      create_pool
      create_vm
      ;;
    *network*)        # action
      # Configure network
      configure_network
      ;;
    customize|post*)  # action
      # Do postinstall config
      customize_vm
      ;;
    deletepool)       # action
      # Delete pool
      delete_pool
      ;;
    deletevm)         # action
      # Delete VM
      check_config
      delete_pool
      delete_vm
      ;;
    getimage)         # action
      # Get image
      do_get_image="true"
      ;;
    *group*)          # action
      # Add group to to VM image
      add_group
      ;;
    *host*)
      # Set hostname in a VM image
      set_hostname
      ;;
    *inject*)         # action
      # Inject SSH key into VM image
      inject_key
      ;;
    install*)         # action
      # Install packages in VM image
      install_packages
      ;;
    listvm*)          # action
      # List VMs
      list_vms
      ;;
    listpool*)        # action
      # List pools
      list_pools
      ;;
    listnet*)         # action
      # List nets
      list_nets
      ;;
    listsnap*)        # action
      # List snapshots
      list_snapshots
      ;;
    *password*)       # action
      # Set password for user in VM image
      set_password
      ;;
    restart*|reboot*) # action
      # Restart VM
      stop_vm
      start_vm
      ;;
    restore*)         # action
      # Restore snapshot
      restore_snapshot
      ;;
    resume*)          # action
      # Resume VM
      resume_vm
      ;;
    exec)             # action
      # Run command in VM image
      run_command "${vm['command']}"
      ;;
    ssh)              # action
      # SSH to VM
      ssh_to_vm
      ;;
    shellcheck)       # action
      # Check script with shellcheck
      options['shellcheck']="true"
      ;;
    shutdown*|stop*)  # action
      # Stop VM
      stop_vm
      ;;
    start*|boot*)     # action
      # Start VM
      start_vm
      ;;
    sshkey*)
      # Generate root SSH keys for SSH server
      create_keys
      ;;
    sudo*)            # action
      # Add sudoers entry to VM image
      add_sudoers
      ;;
    suspend*)         # action
      # Suspend VM
      suspend_vm
      ;;
    *user*)           # action
      # Add user to VM
      add_user
      ;;
    version)          # action
      # Print version
      print_version
      exit
      ;;
    *)
      print_usage "actions"
      exit
      ;;
  esac
}

# Process options

process_options () {
  option="$1"
  case "${option}" in
    debug)          # option
      # Enable debug mode
      options['debug']="true"
      ;;
    dryrun)         # option
      # Enable dryrun mode (don't execute commands)
      options['dryrun']="true"
      ;;
    dhcp)           # option
      # Use DHCP
      vm['dhcp']="true"
      ;;
    force)          # option
      # Force action
      options['force']="true"
      ;;
    nohwe*)         # option
      # Disable HWE kernel
      options['hwe']="false"
      ;;
    hwe*)           # option
      # Enable HWE kernel
      options['hwe']="true"
      ;;
    noautoconsole)  # option
      # Disable autoconsole
      options['autoconsole']="false"
      ;;
    autoconsole)    # option
      # Enable autoconsole
      options['autoconsole']="true"
      ;;
    noautostart)    # option
      # Disable autostart
      options['autostart']="false"
      ;;
    autostart)      # option
      # Enable autostart
      options['autostart']="true"
      ;;
    nolocalds)      # option
      # Don't use cloud-localds
      options['localds']="false"
      ;;
    localds)        # option
      # Use cloud-localds
      options['localds']="true"
      ;;
    nolock*)        # option
      # Lock password
      options['lock']="false"
      ;;
    lock*)          # option
      # Lock password
      options['lock']="true"
      ;;
    nobacking)      # option
      # Don't use backing (creates a full copy of image)
      options['backing']="false"
      ;;
    options|help)   # option
      # Print options help
      print_usage "options"
      exit
      ;;
    nomask)         # option
      # Disable masking of password and ssh keys
      options['mask']="false"
      ;;
    mask)           # option
      # Enable masking of password and ssh keys
      options['mask']="true"
      ;;
    nopassthrough)    # option
      # Enable passthrough
      options['passthrough']="false"
      ;;
    passthrough)    # option
      # Enable passthrough
      options['passthrough']="true"
      ;;
    noreboot)       # option
      # Disable reboot
      options['reboot']="false"
      ;;
    reboot)         # option
      # Enable reboot
      options['reboot']="true"
      ;;
    nosecureboot)   # option
      # Disable secureboot
      options['secureboot']="false"
      ;;
    secureboot)     # option
      # Enable secureboot
      options['secureboot']="true"
      ;;
    strict)         # option
      # Enable strict mode
      options['strict']="true"
      ;;
    verbose)        # option
      # Enable verbose mode
      options['verbose']="true"
      ;;
    version)        # option
      # Print version
      print_version
      exit
      ;;
    *)
      print_usage "options"
      ;;
  esac
  if [ "${options['passthrough']}" = "true" ]; then
    vm['cputype']="host-passthrough"
    vm['features']="kvm_hidden=on"
  fi
  if [ "${options['hwe']}" = "true" ]; then
    vm['kernel']="linux-generic-hwe-${vm['release']}"
    vm['packages']="${vm['packages']},${vm['kernel']}"
  fi
  if [ "${vm['boot']}" = "uefi" ]; then
    if [ "${options['secureboot']}" = "true" ]; then
      vm['boot']="${vm['boot']},loader_secure=yes"
    else
      vm['boot']="${vm['boot']},loader_secure=no"
    fi
  fi
}



# Set defaults

set_defaults

# Handle verbose and debug early so it's enabled early

if [[ "$*" =~ "strict" ]]; then
  options['verbose']="true"
  set -u
fi

if [[ "$*" =~ "debug" ]]; then
  options['verbose']="true"
  set -x
fi

if [[ "$*" =~ "verbose" ]]; then
  options['verbose']="true"
fi

# Handle commandline arguments

while test $# -gt 0; do
  case $1 in
    --action*)             # switch
      # Action to perform (e.g. createvm,deletevm)
      check_value "$1" "$2"
      actions="$2"
      options['actions']="true"
      shift 2
      ;;
    --arch)               # switch
      # Specify architecture
      check_value "$1" "$2"
      vm['arch']="$2"
      shift 2
      ;;
    --boot*)              # switch
      # VM boot type (e.g. UEFI)
      check_value "$1" "$2"
      vm['boot']="$2"
      shift 2
      ;;
    --bridge)             # switch
      # VM network bridge
      check_value "$1" "$2"
      vm['bridge']="$2"
      shift 2
      ;;
    --cdrom)              # switch
      # VM localds cdrom
      check_value "$1" "$2"
      vm['cdrom']="$2"
      shift 2
      ;;
    --cidr)               # switch
      # VM CIDR
      check_value "$1" "$2"
      vm['cidr']="$2"
      shift 2
      ;;
    --cloud*)              # switch
      # VM cloud-init config
      check_value "$1" "$2"
      vm['initcfg']="$2"
      shift 2
      ;;
    --*codename)           # switch
      # VM cloud-init config
      check_value "$1" "$2"
      vm['codename']="$2"
      shift 2
      ;;
    --cpus)               # switch
      # Number of VM CPUs
      check_value "$1" "$2"
      vm['cpus']="$2"
      shift 2
      ;;
    --cputype)            # switch
      # Type of CPU within VM
      check_value "$1" "$2"
      vm['cputype']="$2"
      shift 2
      ;;
    --crypt)              # switch
      # VM password crypt
      check_value "$1" "$2"
      vm['crypt']="$2"
      shift 2
      ;;
    --debug)              # switch
      # Run in debug mode
      options['debug']="true"
      shift
      ;;
    --dest*)              # switch
      # Destination of file to copy into VM disk
      check_value "$1" "$2"
      vm['destfile']="$2"
      shift 2
      ;;
    --desc*)              # switch
      # description of snapshot
      check_value "$1" "$2"
      vm['description']="$2"
      shift 2
      ;;
    --disk)               # switch
      # VM disk file
      check_value "$1" "$2"
      vm['disk']="$2"
      shift 2
      ;;
    --dns)                # switch
      # VM DNS server
      check_value "$1" "$2"
      vm['dns']="$2"
      shift 2
      ;;
    --domain*)            # switch
      # VM domainname
      check_value "$1" "$2"
      vm['domain']="$2"
      shift 2
      ;;
    --dryrun)             # switch
      # Run in dryrun mode
      options['dryrun']="true"
      shift
      ;;
    --exec)               # switch
      # Command to run in VM image
      check_value "$1" "$2"
      vm['command']="$2"
      shift 2
      ;;
    --features)           # switch
      # VM features
      check_value "$1" "$2"
      vm['features']="$2"
      shift 2
      ;;
    --filegroup)          # switch
      # Set group of a file within VM image
      check_value "$1" "$2"
      vm['filegroup']="$2"
      shift 2
      ;;
    --fileowner)          # switch
      # Set owner of a file within VM image
      check_value "$1" "$2"
      vm['fileowner']="$2"
      shift 2
      ;;
    --fileperms)          # switch
      # Set permissions of a file within VM image
      check_value "$1" "$2"
      vm['fileperms']="$2"
      shift 2
      ;;
    --force)              # switch
      # Force mode
      options['force']="true"
      shift
      ;;
    --fqdn)               # switch
      # VM FQDN
      check_value "$1" "$2"
      vm['fqdn']="$2"
      shift 2
      ;;
    --getimage)           # switch
      # Get Image
      get_image
      shift
      exit
      ;;
    --gateway|--router)   # switch
      # VM gateway address
      check_value "$1" "$2"
      vm['gateway']="$2"
      shift 2
      ;;
    --graphics)           # switch
      # VM Graphics type
      check_value "$1" "$2"
      vm['graphics']="$2"
      shift 2
      ;;
    --gecos)              # switch
      # GECOS field for user
      check_value "$1" "$2"
      vm['gecos']="$2"
      shift 2
      ;;
    --groupid|--gid)      # switch
      # Group ID
      check_value "$1" "$2"
      vm['groupid']="$2"
      shift 2
      ;;
    --group|--groupname)  # switch
      # Primary Group a user is member of in VM image
      check_value "$1" "$2"
      vm['groupname']="$2"
      shift 2
      ;;
    --groups)             # switch
      # Additional groups a user is a member of in VM image
      check_value "$1" "$2"
      vm['groups']="$2"
      shift 2
      ;;
    --help|--usage|-h)    # switch
      # Print help
      print_usage "$2"
      shift 2
      exit
      ;;
    --home*)              # switch
      # Home directory
      check_value "$1" "$2"
      vm['homedir']="$2"
      shift 2
      ;;
    --hostdevice)         # switch
      # VM host device pass-through
      check_value "$1" "$2"
      vm['hostdevice']="$2"
      options['passthrough']="true"
      shift 2
      ;;
    --hostname)           # switch
      # VM hostname
      check_value "$1" "$2"
      vm['hostname']="$2"
      shift 2
      ;;
    --imagedir)           # switch
      # Image directory
      check_value "$1" "$2"
      vm['imagedir']="$2"
      shift 2
      ;;
    --imagefile)          # switch
      # Image file
      check_value "$1" "$2"
      vm['imagefile']="$2"
      shift 2
      ;;
    --imageurl)           # switch
      # Image URL
      check_value "$1" "$2"
      vm['imageurl']="$2"
      shift 2
      ;;
    --ip*)                # switch
      # VM IP address
      check_value "$1" "$2"
      vm['ip']="$2"
      shift 2
      ;;
    --kernel*)            # switch
      # VM kernel
      check_value "$1" "$2"
      vm['kernel']="$2"
      shift 2
      ;;
    --mask)               # switch
      # Enable masking of password and ssh keys
      options['mask']="true"
      shift
      ;;
    --name|--vmname)      # switch
      # Name of VM
      check_value "$1" "$2"
      vm['name']="$2"
      shift 2
      ;;
    --nettype)            # switch
      # Net type (e.g. bridge)
      check_value "$1" "$2"
      vm['nettype']="$2"
      shift 2
      ;;
    --netbus|netdriver)   # switch
      # Net bus/driver (e.g. virtio)
      check_value "$1" "$2"
      vm['netbus']="$2"
      shift 2
      ;;
    --netc*|--networkc*)  # switch
      # VM network config file
      check_value "$1" "$2"
      vm['netcfg']="$2"
      shift 2
      ;;
    --netdev|--nic)       # switch
      # VM network device (e.g. enp1s0)
      check_value "$1" "$2"
      vm['netdev']="$2"
      shift 2
      ;;
    --option*)             # switch
      # Option(s) (e.g. verbose,dryrun)
      check_value "$1" "$2"
      options="$2"
      options['options']="true"
      shift 2
      ;;
    --osvariant)          # switch
      # Os variant
      check_value "$1" "$2"
      vm['osvariant']="$2"
      shift 2
      ;;
    --osvers|--release)             # switch
      # OS version of image
      check_value "$1" "$2"
      vm['release']="$2"
      shift 2
      ;;
    --packages)           # switch
      # Packages to install in VM
      check_value "$1" "$2"
      vm['packages']="$2"
      shift 2
      ;;
    --password)           # switch
      # Password for user (e.g. root)
      check_value "$1" "$2"
      vm['password']="$2"
      shift 2
      ;;
    --poolname)           # switch
      # Pool name
      check_value "$1" "$2"
      vm['poolname']="$2"
      shift 2
      ;;
    --pooldir)            # switch
      # Pool directory
      check_value "$1" "$2"
      vm['pooldir']="$2"
      shift 2
      ;;
    --post*)              # switch
      # Post install script
      check_value "$1" "$2"
      vm['postscript']="$2"
      shift 2
      ;;
    --power*)             # switch
      # VM power state
      check_value "$1" "$2"
      vm['power']="$2"
      shift 2
      ;;
    --ram)                # switch
      # Amount of VM RAM
      check_value "$1" "$2"
      vm['ram']="$2"
      shift 2
      ;;
    --runcmd)             # switch
      # Run command during install
      check_value "$1" "$2"
      vm['runcmd']="$2"
      shift 2
      ;;
    --shell)              # switch
      # User shell in VM image
      check_value "$1" "$2"
      vm['shell']="$2"
      shift 2
      ;;
    --size)               # switch
      # Size of VM disk
      check_value "$1" "$2"
      vm['size']="$2"
      shift 2
      ;;
    --shellcheck)         # switch
      # Run shellcheck on script
      options['shellcheck']="true"
      shift
      ;;
    --snap*)              # switch
      # Name of snapshot
      check_value "$1" "$2"
      vm['snapshot']="$2"
      shift 2
      ;;
    --source*|--input*)   # switch
      # Source file to copy into VM disk
      check_value "$1" "$2"
      vm['sourcefile']="$2"
      shift 2
      ;;
    --sshkey)             # switch
      # SSH key
      check_value "$1" "$2"
      vm['sshkey']="$2"
      shift 2
      ;;
    --sshkeyfile)             # switch
      # SSH key file
      check_value "$1" "$2"
      vm['sshkeyfile']="$2"
      shift 2
      ;;
    --strict)             # switch
      # Run in strict mode
      options['strict']="true"
      shift
      ;;
    --sudoers)            # switch
      # Sudoers entry
      check_value "$1" "$2"
      vm['sudoers']="$2"
      shift 2
      ;;
    --userid|--uid)       # switch
      # User ID
      check_value "$1" "$2"
      vm['userid']="$2"
      shift 2
      ;;
    --user|--username)    # switch
      # Username
      check_value "$1" "$2"
      vm['username']="$2"
      shift 2
      ;;
    --verbose)            # switch
      # Run in verbose mode
      options['verbose']="true"
      shift
      ;;
    --version|-V)         # switch
      # Print version
      print_version
      shift
      exit
      ;;
    --virtdir)            # switch
      # VM/libvirt base directory
      check_value "$1" "$2"
      vm['virtdir']="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_usage ""
      exit
      ;;
  esac
done


if [ "${options['shellcheck']}" = "true" ]; then
  check_shellcheck
  exit
fi

# Reset default based on switches

if [ ! "${vm['hostname']}" = "" ]; then
  check_vm_name
fi

reset_defaults

# Process options

if [ "${options['options']}" = "true" ]; then
  if [[ "${options}" =~ , ]]; then
    IFS="," read -r -a array <<< "${options}"
    for option in "${array[@]}"; do
      process_options "${option}"
    done
  else
    process_options "${options}"
  fi
fi

# Process actions

if [ "${options['actions']}" = "true" ]; then
  if [[ "${actions}" =~ "," ]]; then
    IFS="," read -r -a array <<< "${actions}"
    for action in "${array[@]}"; do
      process_actions "${action}"
    done
  else
    process_actions "${actions}"
  fi
fi
