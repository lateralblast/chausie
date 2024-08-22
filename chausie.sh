#!/usr/bin/env bash

# Name:         chausie (Cloud-Image Host Automation Utility and System Image Engine)
# Version:      0.1.1
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

script_args="$*"
script_name="chausie"
script_path=$( pwd )
script_bin=$( basename "$0" |sed "s/^\.\///g")
script_file="$script_path/$script_bin"
script_vers=$( grep '^# Version' < "$0" | awk '{print $3}' )
os_name=$( uname )
os_arch=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
os_user=$( whoami )
os_group=$( id -gn )
mod_path="$script_path/modules"
script_help=$( grep -A1 "# switch" "$0" |sed "s/^--//g" |sed "s/# switch//g" | tr -s " " |grep -v "=" )
script_actions=$( grep -A1 "# action" "$0" |sed "s/^--//g" |sed "s/# action//g" | tr -s " " |grep -v "=" )
script_options=$( grep -A1 "# option" "$0" |sed "s/^--//g" |sed "s/# option//g" | tr -s " " |grep -v "=" )

# Print help

print_help () {
  echo "Usage: $script_bin [OPTIONS...]"
  echo ""
  echo "$script_help"
  echo ""
}

# Print actions

print_actions () {
  echo "Actions:"
  echo "$script_actions"
  echo ""
}

# Print options

print_options () {
  echo "Options:"
  echo "$script_options"
  echo ""
}

# Print Usage

print_usage () {
  usage="$1"
  case $usage in
    help)
      print help
      ;;
    action*)
      print_actions
      ;;
    options)
      print_options
      ;;
    *)
      print_help
      print_actions
      print_options
      ;;
  esac
}

# Print version

print_version () {
  echo "$script_vers"
}

# Exit routine

do_exit () {
  if [ ! "$do_dryrun" = "true" ]; then
    exit
  fi
}

# Check value

check_value () {
  parameter="$1"
  value="$2"
  if [[ "$value" =~ "--" ]]; then
    verbose_message "Value '$value' for parameter '$parameter' looks like a parameter" "warn"
    if [ "$do_force" = "false" ]; then
      do_exit
    fi
  fi
}

# Install required packages

check_packages () {
  for package in $required_packages; do
    package_check=$( echo "$installed_packages" |grep -c "^$package$" )
    if [ "$package_check" = "0" ]; then
      if [ "$os_name" = "Darwin" ]; then
        execute_command "brew install $package" ""
      else
        execute_command "apt get install $package" "su"
      fi
    fi
  done
}

# Run Shellcheck

check_shellcheck () {
  bin_test=$( command -v shellcheck | grep -c shellcheck )
  if [ ! "$bin_test" = "0" ]; then
    shellcheck "$script_file"
  fi
}

# Set defaults

set_defaults () {
  vm_name=""
  vm_disk=""
  image_name="" 
  image_file=""
  image_dir=""
  image_url=""
  pool_name=""
  pool_dir=""
  release_dir=""
  do_actions="false"
  do_options="false"
  do_verbose="false"
  do_strict="false"
  do_dryrun="false"
  do_debug="false"
  do_force="false"
  do_shellcheck="false"
  do_create_vm="false"
  do_check_config="false"
  do_get_image="false"
  do_create_pool="false"
  vm_arch="$os_arch"
  vm_cpus="2"
  vm_ram="2048"
  vm_size="20G"
  os_vers="24.04"
  if [ "$os_name" = "Darwin" ]; then
    vm_bridge="default"
    brew_dir="/opt/homebrew/Cellar"
    if [ ! -d "$brew_dir" ]; then
      brew_dir="/usr/local/Cellar"
    fi
    virt_dir="$brew_dir/libvirt"
    installed_packages=$( brew list )
    required_packages="qemu libvirt libvirt-glib libvirt-python virt-manager"
  else
    vm_bridge="br0"
    virt_dir="/var/lib/libvirt"
    installed_packages=$( dpkg -l |grep ^ii |awk '{print $2}' )
    required_packages="qemu libvirt libvirt-glib libvirt-python virt-manager"
  fi
  image_dir="$virt_dir/images"
}

# Verbose message

verbose_message () {
  message="$1"
  format="$2"
  if [ "$do_verbose" = "true" ] || [ "$format" = "verbose" ]; then
    case "$format" in
      "execute")
        echo "Executing: $message"
        ;;
      "warn")
        echo "Warning:   $message"
        ;;
      "notice")
        echo "Notice:    $message"
        ;;
      "verbose")
        echo "$message"
        ;;
      *)
        echo "$message"
        ;;
    esac
  fi
}

# Execute command

execute_command () {
  command="$1"
  privilege="$2"
  if [ "$privilege" = "su" ]; then
    command="sudo sh -c '$command'"
  fi
  if [ "$privilege" = "linuxsu" ]; then
    if [ "$os_name" = "Linux" ]; then
      command="sudo sh -c '$command'"
    fi
  fi
  if [ "$do_verbose" = "true" ]; then
    verbose_message "$command" "execute"
  fi
  if [ "$do_dryrun" = "false" ]; then
    eval "$command"
  fi
}

# Handle verbose and debug early so it's enabled early

if [[ "$*" =~ "strict" ]]; then
  do_verbose="true"
  set -eu
else
  do_verbose="false"
fi

if [[ "$*" =~ "debug" ]]; then
  do_verbose="true"
  set -x
else
  do_verbose="false"
fi

# Load modules

if [ -d "$mod_path" ]; then
  modules=$( ls "$mod_path"/*.sh )
  for module in "${modules[@]}"; do
    if [[ "$script_args" =~ "verbose" ]]; then
      echo "Loading Module: $module"
    fi
    . "$module"
  done
fi

# If given no arguments print help

if [ "$script_args" = "" ]; then
  print_help
  exit
fi

# Check config

check_config () {
  verbose_message "Checking config" "verbose"
  for check_dir in $virt_dir $image_dir; do
    if [ ! -d "$check_dir" ]; then
      execute_command "mkdir -p $virt_dir" "su"
    fi
  done
  if [ "$os_name" = "Linux" ]; then
    group_check=$( stat -c "%G" /dev/kvm )
    if [ ! "$group_check" = "kvm" ]; then
      execute_command "chown root:kvm /dev/kvm" "su"
    fi
    for group in kvm libvirt libvirt-qemu; do
      group_check=$( groups |grep -c "$group " )
      if [ "$group_check" = "0" ]; then
        execute_command "usermod -a -G $group $os_user" "su"
      fi
    done
  fi
  check_packages
}

# Create libvirt dir

create_libvirt_dir () {
  new_dir="$1" 
  if [ ! -d "$new_dir" ]; then
    execute_command "mkdir -p $new_dir" "linuxsu"
    if [ "$os_name" = "Linux" ]; then 
      execute_command "chown root:libvirt $new_dir" "su"
      execute_command "chmod 775 $new_dir" "su"
    fi
  else
    verbose_message "Directory \"$new_dir\" already exists" "notice"
  fi
}

# Get image

get_image () {
  if [ "$image_dir" = "" ]; then
    image_dir="$virt_dir/images"
  fi
  create_libvirt_dir "$image_dir"
  if [ "$image_file" = "" ]; then
    image_file="ubuntu-$os_vers-server-cloudimg-$vm_arch.img"
  fi
  if [ "$image_url" = "" ]; then
    image_url="https://cloud-images.ubuntu.com/releases/$os_vers/release/$image_file"
  fi
  if [ ! -f "$image_dir/$image_file" ]; then
    execute_command "cd $image_dir ; wget $image_url" "sulinux"
  else
    verbose_message "Cloud Image \"$image_file\" already exists" "notice"
  fi
}

# Create Pool

create_pool () {
  pool_name="$1"
  pool_dir="$2"
  create_libvirt_dir "$pool_dir"
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ ! "$pool_test" =~ "$pool_name" ]]; then
    execute_command "virsh pool-create-as --name $pool_name --type dir --target $pool_dir" ""
  else
    verbose_message "Pool \"$pool_name\" already exists" "notice"
  fi
}

# Delete Pool

delete_pool () {
  pool_name="$1"
  pool_dir="$2"
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ "$pool_test" =~ "$pool_name" ]]; then
    execute_command "virsh pool-delete --name $pool_name" ""
  else
    verbose_message "Pool \"$pool_name\" does not exist" "notice"
  fi
  delete_libvirt_dir "$pool_dir"
}

# Create VM

create_vm () {
  if [ ! -f "$image_dir/$image_file" ]; then 
    verbose_message "Image file $image_dir/$image_file does not exist" "warn"
    do_exit
  fi
  if [ -f "$vm_disk" ]; then
    verbose_message "VM disk file $vm_disk already exists" "warn"
    do_exit
  fi
#  virt-install --import --name $vm_name --memory 4096 --vcpus 4 --cpu host --disk haos_ova-13.0.qcow2,format=qcow2,bus=virtio --network bridge=br0,model=virtio --osinfo detect=on,require=off --graphics none --noautoconsole --boot uefi
}

# Reset defaults

reset_defaults () {
  if [ "$do_debug" = "true" ]; then
    set -x
  fi
  if [ "$do_strict" = "true" ]; then
    set -eu
  fi
  if [ "$vm_arch" = "" ]; then
    vm_arch="$os_arch"
  fi
  if [ "$vm_name" = "" ]; then
    vm_name="$script_name"
  fi
  if [ "$image_dir" = "" ]; then
    image_dir="$virt_dir/images"
  fi
  if [ "$vm_disk" = "" ]; then
    vm_disk="$virt_dir/$vm_name/$vm_name.qcow2"
  fi
  if [ "$pool_name" = "" ]; then
    pool_name="$vm_name"
  fi
  if [ "$pool_dir" = "" ]; then
    pool_dir="$image_dir/$pool_name"
  fi
  if [ "$release_dir" = "" ]; then
    release_dir="$image_dir/releases"
  fi
  create_libvirt_dir "$release_dir"
}

# Process action

process_actions () {
  actions="$1"
  case $actions in
    action|help) # action
      # Print actions help
      print_usage "actions"
      exit
      ;;
    createvm) # action
      # Create VM
      do_check_config="true"
      do_create_pool="true"
      do_create_vm="true"
      ;;
    *config) # action
      # Check config
      do_check_config="true"
      ;;
    createpool) # action
      # Create pool
      do_create_pool="true"
      ;;
    shellcheck) # action
      # Check script with shellcheck
      do_shellcheck="true"
      ;;
    version) # action
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
  options="$1"
  case $options in
    *debug*) # option
      # Enable debug mode
      do_debug="true"
      ;;
    *dryrun*) # option
      # Enable dryrun mode
      do_dryrun="true"
      ;;
    *strict*) # option
      # Enable strict mode
      do_strict="true"
      ;;
    *verbose*) # option
      # Enable verbose mode
      do_verbose="true"
      ;;
    options|help) # option
      # Print options help
      print_usage "options"
      exit
      ;;
    version) # option
      # Print version
      print_version
      exit
      ;;
    *)
      print_usage "options"
      ;;
  esac    
}

# Set defaults

set_defaults

# Handle commandline arguments

while test $# -gt 0; do
  case $1 in
    --action) # switch
      # Action to perform
      check_value "$1" "$2"
      actions="$2"
      do_actions="true"
      shift 2
      ;;
    --actions) # switch
      # Print actions
      print_usage "actions"
      shift
      exit
      ;;
    --arch) # switch
      # Specify architecture
      check_value "$1" "$2"
      vm_arch="$2"
      shift 2
      ;;
    --bridge) # switch
      # VM network bridge
      check_value "$1" "$2"
      vm_bridge="$2"
      shift 2
      ;;
    --checkconfig) # switch
      # Check config
      do_check_config="true"
      shift
      ;;
    --cpus) # switch
      # Number of VM CPUs
      check_value "$1" "$2"
      vm_cpus="$2"
      shift 2
      ;;
    --debug) # switch
      # Run in debug mode
      do_debug="true"
      shift
      ;;
    --disk) # switch
      # VM disk file
      check_value "$1" "$2"
      vm_disk="$2"
      shift 2
      ;;
    --dryrun) # switch
      # Run in dryrun mode
      do_dryrun="true"
      shift
      ;;
    --force) # switch
      # Force mode
      do_force="true"
      shift
      ;;
    --getimage) # switch
      # Get Image
      do_get_image="true"
      shift
      ;;
    --help|--usage|-h) # switch
      # Print help
      print_usage "$2"
      shift 2
      exit
      ;;
    --imagedir) # switch
      # Image directory
      check_value "$1" "$2"
      image_dir="$2"
      shift 2
      ;;
    --imagefile) # switch
      # Image file
      check_value "$1" "$2"
      image_file="$2"
      shift 2
      ;;
    --imageurl) # switch
      # Image URL
      check_value "$1" "$2"
      image_url="$2"
      shift 2
      ;;
    --name) # switch
      # Name of VM
      check_value "$1" "$2"
      vm_name="$2"
      shift 2
      ;;
    --options) # switch
      # Options
      check_value "$1" "$2"
      options="$2"
      do_options="true"
      shift 2
      ;;
    --osvers) # switch
      # OS version of image
      check_value "$1" "$2"
      os_vers="$2"
      shift 2
      ;;
    --poolname) # switch
      # Pool name
      check_value "$1" "$2"
      pool_name="$2"
      shift 2
      ;;
    --pooldir) # switch
      # Pool directory
      check_value "$2"
      pool_dir="$2"
      shift 2
      ;;
    --ram) # switch
      # Amount of VM RAM
      check_value "$1" "$2"
      vm_ram="$2"
      shift 2
      ;;
    --size) # switch
      # Size of VM disk
      check_value "$1" "$2"
      vm_size="$2"
      shift 2
      ;;
    --shellcheck)
      # Run shellcheck on script
      do_shellcheck="true"
      shift
      ;;
    --strict) # switch
      # Run in strict mode
      do_strict="true"
      shift
      ;;
    --verbose) # switch
      # Run in verbose mode
      do_verbose="true"
      shift
      ;;
    --version|-V) # switch
      # Print version
      print_version
      shift
      exit
      ;;
    --virtdir) # switch
      # VM base directory
      check_value "$1" "$2"
      virt_dir="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_usage
      exit
      ;;
  esac
done

reset_defaults
if [ "$do_shellcheck" = "true" ]; then
  check_shellcheck
  exit
fi
if [ "$do_actions" = "true" ]; then
  process_actions "$actions"
fi
if [ "$do_options" = "true" ]; then
  if [[ "$options" =~ "," ]]; then
    IFS="," read -r -a array <<< "$options"
    for option in "${array[@]}"; do
      process_options "$option"
    done
  else
    process_options "$options"
  fi
fi
if [ "$do_check_config" = "true" ]; then
  check_config
fi
if [ "$do_get_image" = "true" ]; then
  get_image
fi
if [ "$do_create_pool" = "true" ]; then
  create_pool "$pool_name" "$pool_dir"
fi
if [ "$do_create_vm" = "true" ]; then
  create_vm
fi
