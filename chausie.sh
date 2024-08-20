#!/usr/bin/env bash

# Name:         chausie (Cloud-Image Host Automation Utility and System Image Engine)
# Version:      0.0.1
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

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2045
# shellcheck disable=SC1090

app_args="$*"
app_name="chausie"
app_path=$( pwd )
app_bin=$( basename "$0" |sed "s/^\.\///g")
app_file="$app_path/$app_bin"
app_vers=$( grep '^# Version' < "$0" | awk '{print $3}' )
os_name=$( uname )
os_arch=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
os_user=$( whoami )
os_group=$( id -gn )
mod_path="$app_path/modules"
app_help=$( grep -A1 "\--[A-Z,a-z]" "$0" |sed "s/^--//g" |sed "s/# //g" | tr -s " " )

# Print help

print_help () {
  echo "Usage: $app_bin [OPTIONS...]"
  echo ""
  echo "$app_help"
  echo ""
  exit
}

# Print version

print_version () {
  echo "$app_vers"
  exit
}

# Set defaults

set_defaults () {
  do_verbose="false"
  do_dryrun="false"
  do_create="false"
  vm_arch="$os_arch"
  virt_dir="/var/lib/libvirt"
  image_dir="$virt_dir/images"
  vm_cpus="2"
  vm_ram="2048"
  vm_size="20G"
  vm_bridge="br0"
}

# Verbose message

verbose_message () {
  message="$1"
  format="$2"
  case "$format" in
    "execute")
      echo "Executing: $message"
      ;;
    "warn")
      echo "Warning:   $message"
      ;;
    *)
      echo "$message"
  esac
}

# Execute command

execute_command () {
  command="$1"
  privilege="$2"
  if [ "$privilege" = "su" ]; then
    command="sudo sh -c '$command'"
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
  for module in $( ls "$mod_path"/*.sh ); do
    if [[ "$app_args" =~ "verbose" ]]; then
      echo "Loading Module: $module"
    fi
    . "$module"
  done
fi

# If given no arguments print help

if [ "$app_args" = "" ]; then
  print_help
fi

# Check config

check_config () {
  for check_dir in $virt_dir $image_dir; do
    if [ ! -d "$check_dir" ]; then
      execute_command "mkdir -p $virt_dir" "su"
    fi
  done
}

# Get image

get_image () {
  image_file="ubuntu-$os_vers-server-cloudimg-$vm_arch.img"
  image_url="https://cloud-images.ubuntu.com/releases/$os_vers/release/$image_file"
  if [ ! -f "$image_dir/$image_file" ]; then
    execute_command "cd $image_dir ; wget $image_url"
  fi
}

# Create VM

create_vm () {
  :
}

# Reset defaults

reset_defaults () {
  if [ "$vm_arch" = "" ]; then
    vm_arch="$os_arch"
  fi
}

# Set defaults

set_defaults

# Handle commandline arguments

while test $# -gt 0; do
  case $1 in
    --arch)
      # Specify architecture
      vm_arch="$2"
      shift 2
      ;;
    --bridge)
      # VM network bridge
      vm_bridge="$2"
      shift 2
      ;;
    --cpus)
      # Number of VM CPUs
      vm_cpus="$2"
      shift 2
      ;;
    --debug)
      # Run in debug mode
      set -x
      shift
      ;;
    --create)
      # Create VM
      do_create="true"
      shift
      ;;
    --dryrun)
      # Run in dryrun mode
      do_dryrun="true"
      shift
      ;;
    --help)
      # Print help
      print_help
      shift
      ;;
    --imagedir)
      # Image directory
      image_dir="$2"
      shift 2
      ;;
    --name)
      # Name of VM
      vm_name="$2"
      shift 2
      ;;
    --ram)
      # Amount of VM RAM
      vm_ram="$2"
      shift 2
      ;;
    --size)
      # Size of VM disk
      vm_size="$2"
      shift 2
      ;;
    --strict)
      # Run in strict mode
      set -eu
      shift
      ;;
    --verbose)
      # Run in verbose mode
      do_verbose="true"
      shift
      ;;
    --version)
      # Print version
      print_version
      shift
      ;;
    --virtdir)
      # VM base directory
      virt_dir="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_help
      exit
      ;;
  esac
done

reset_defaults
