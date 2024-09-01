#!/usr/bin/env bash

# Name:         chausie (Cloud-Image Host Automation Utility and System Image Engine)
# Version:      0.4.2
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

# Set/get some environment parameters

script_args="$*"
script_name="chausie"
script_path=$( pwd )
script_bin=$( basename "$0" |sed "s/^\.\///g")
script_file="$script_path/$script_bin"
script_dir=$( dirname "$script_file" )
script_vers=$( grep '^# Version' < "$0" | awk '{print $3}' )
os_name=$( uname )
os_arch=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
os_user=$( whoami )
os_group=$( id -gn )
os_home="$HOME"
mod_path="$script_path/modules"

export LIBGUESTFS_BACKEND=direct

# Print help

print_help () {
  script_help=$( grep -A1 "# switch" "$script_file" |sed "s/^--//g" |sed "s/# switch//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/-/g" )
  echo "Usage: $script_bin [OPTIONS...]"
  echo "-----"
  echo "$script_help"
  echo ""
}

# If given no arguments print help

if [ "$script_args" = "" ]; then
  print_help
  exit
fi

# Print actions

print_actions () {
  script_actions=$( grep -A1 "# action" "$script_file" |sed "s/^--//g" |sed "s/# action//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/-/g" )
  echo "Actions:"
  echo "-------"
  echo "$script_actions"
  echo ""
}

# Print options

print_options () {
  script_options=$( grep -A1 "# option" "$script_file" |sed "s/^--//g" |sed "s/# option//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/-/g" )
  echo "Options:"
  echo "-------"
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
  if [ "$do_dryrun" = "false" ]; then
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
        execute_command "apt-get install $package" "su"
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
  ssh_key=""
  do_actions="false"
  do_options="false"
  do_verbose="false"
  do_strict="false"
  do_dryrun="false"
  do_debug="false"
  do_force="false"
  do_post="false"
  do_command="false"
  do_shellcheck="false"
  do_backing="true"
  do_create_vm="false"
  do_delete_vm="false"
  do_start_vm="false"
  do_stop_vm="false"
  do_check_config="false"
  do_get_image="false"
  do_create_pool="false"
  do_delete_pool="false"
  do_autoconsole="false"
  do_autostart="false"
  do_reboot="false"
  do_connect="false"
  do_upload="false"
  do_list_vms="false"
  do_list_pools="false"
  do_list_nets="false"
  do_inject_key="false"
  do_password="false"
  do_network="false"
  do_hostname="false"
  do_install="false"
  vm_dhcp="false"
  vm_cpus=""
  vm_ram=""
  vm_size=""
  os_vers=""
  vm_boot=""
  vm_graphics=""
  vm_arch=""
  vm_osvariant=""
  vm_command=""
  vm_username=""
  vm_password=""
  vm_net_type=""
  vm_net_bus=""
  vm_net_dev=""
  vm_cidr=""
  vm_dns=""
  vm_ip=""
  vm_gateway=""
  vm_bridge=""
  vm_cputype=""
  vm_hostname=""
  vm_domain=""
  vm_fqdn=""
  source_file=""
  dest_file=""
  post_script=""
  cache_dir=""
  virt_dir=""
  if [ "$os_name" = "Darwin" ]; then
    installed_packages=$( brew list )
    required_packages="qemu libvirt libvirt-glib libvirt-python virt-manager libosinfo"
  else
    vm_bridge="br0"
    installed_packages=$( dpkg -l |grep ^ii |awk '{print $2}' )
    required_packages="virt-manager libosinfo-bin libguestfs-tools"
  fi
  image_dir=""
}

# Verbose message

verbose_message () {
  message="$1"
  format="$2"
  if [ "$do_verbose" = "true" ] || [ "$format" = "verbose" ]; then
    case "$format" in
      "execute")
        echo "Executing:    $message"
        ;;
      "info")
        echo "Information:  $message"
        ;;
      "notice")
        echo "Notice:       $message"
        ;;
      "verbose")
        echo "$message"
        ;;
      "warn")
        echo "Warning:      $message"
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
  if [ "$privilege" = "linuxsu" ] || [ "$privilege" = "sulinux" ]; then
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

# Check config

check_config () {
  verbose_message "Checking config" "info"
  for check_dir in $virt_dir $image_dir $cache_dir; do
    if [ ! -d "$check_dir" ]; then
      execute_command "mkdir -p $virt_dir" "linuxsu"
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

# Fix Linux libvirt perms

fix_libvirt_perms () {
  file_name="$1"
  if [ "$os_name" = "Linux" ]; then
    execute_command "chown root:libvirt-qemu $file_name" "su"
    execute_command "chmod 770 $file_name" "su"
  fi
}

# Create libvirt dir

create_libvirt_dir () {
  new_dir="$1"
  if [ ! -d "$new_dir" ]; then
    execute_command "mkdir -p $new_dir" "linuxsu"
    fix_libvirt_perms "$new_dir"
  else
    verbose_message "Directory \"$new_dir\" already exists" "notice"
  fi
}

# Delete libvirt dir

delete_libvirt_dir () {
  new_dir="$1"
  if [ -d "$new_dir" ] && [ "$new_dir" != "/" ]; then
    execute_command "rm -rf $new_dir" "linuxsu"
  else
    verbose_message "Directory \"$new_dir\" does not exist" "notice"
  fi
}

# Get image

get_image () {
  if [ "$release_dir" = "" ]; then
    release_dir="$image_dir/releases"
  fi
  create_libvirt_dir "$release_dir"
  if [ ! -f "$release_dir/$image_file" ]; then
    execute_command "cd $release_dir ; wget $image_url" "linuxsu"
  else
    verbose_message "Cloud Image \"$release_dir/$image_file\" already exists" "notice"
  fi
}

# Create Pool

create_pool () {
  pool_name="$1"
  pool_dir="$2"
  create_libvirt_dir "$pool_dir"
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ ! "$pool_test" =~ "$pool_name" ]]; then
    execute_command "virsh pool-create-as --name $pool_name --type dir --target $pool_dir > /dev/null 2>&1" ""
    fix_libvirt_perms "$pool_dir"

  else
    verbose_message "Pool \"$pool_name\" already exists" "notice"aaaaaaaa
  fi
}

# Delete Pool

delete_pool () {
  pool_name="$1"
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ "$pool_test" =~ "$pool_name" ]]; then
    execute_command "virsh pool-destroy --pool $pool_name > /dev/null 2>&1" ""
  else
    verbose_message "Pool \"$pool_name\" does not exist" "notice"
  fi
  delete_libvirt_dir "$pool_dir"
}

# Check VM bridge

check_bridge () {
  bridge_check=$( ip link show $vm_bridge 2>&1 |grep "does not exist" |wc -c )
  if [ ! "$bridge_check" = "0" ]; then
    verbose_message "Bridge device \"$vm_bridge\" does not exist" "warn"
    do_exit
  fi
}

# Check Cloud Image exists

check_image_exists () {
  if [ ! -f "$release_dir/$image_file" ]; then
    verbose_message "Cloud Image file \"$release_dir/$image_file\" does not exist" "warn"
    do_exit
  else
    verbose_message "Found Cloud Image file \"$release_dir/$image_file\"" "info"
  fi 
}

# Check VM disk exists

check_disk_exists () {
  if [ -f "$vm_disk" ]; then
    verbose_message "VM disk file \"$vm_disk\" already exists" "warn"
    do_exit
  else
    verbose_message "Creating VM disk file \"$vm_disk\"" "info"
  fi  
}

# Create VM disk

create_disk () {
  if [ "$do_backing" = "true" ]; then
    execute_command "qemu-img create -b $release_dir/$image_file -F qcow2 -f qcow2 $vm_disk $vm_size" "linuxsu"
  else
    execute_command "cp $release__dir/$image_file $vm_disk" "linuxsu"
    execute_command "qemu-img resize $vm_disk $vm_size" "linuxsu"
  fi
}

# Create VM

create_vm () {
  check_bridge
  check_image_exists
  check_disk_exists
  create_disk
  fix_libvirt_perms "$vm_disk"
  if [ "$do_autoconsole" = "false" ]; then
    cli_autoconsole="--noautoconsole"
  else
    cli_autoconsole="--autoconsole $vm_graphics"
  fi
  if [ "$do_autostart" = "false" ]; then
    cli_autostart=""
  else
    cli_autostart="--autostart"
  fi
  cli_name="--name $vm_name"
  cli_memory="--memory $vm_ram"
  cli_vcpus="--vcpus $vm_cpus"
  cli_cpu="--cpu $vm_cputype"
  cli_disk="--disk $vm_disk,format=qcow2,bus=virtio"
  if [ "$os_name" = "Darwin" ]; then
    cli_network=""
  else
    cli_network="--network $vm_net_type=$vm_bridge,model=virtio"
  fi
  cli_osvariant="--os-variant $vm_osvariant"
  cli_graphics="--graphics $vm_graphics"
  cli_boot="--boot $vm_boot"
  if [ "$do_reboot" = "false" ]; then
    cli_reboot="--noreboot"
  fi
  command="virt-install --import $cli_name $cli_memory $cli_vcpus $cli_cpu $cli_disk $cli_network $cli_osvariant $cli_autoconsole $cli_graphics $cli_boot $cli_autostart $cli_reboot"
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "0" ]]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" already exists" "notice"
  fi
}

# Delete VM

delete_vm () {
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]]; then
    execute_command "virsh undefine --nvram $vm_name > /dev/null 2>&1" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "notice"
  fi
}

# Start VM

start_vm () {
  vm_name="$1"
  command="virsh start $vm_name"
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Stop VM

stop_vm () {
  vm_name="$1"
  command="virsh shutdown $vm_name"
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Connect to VM

connect_to_vm () {
  vm_name="$1"
  command="virsh console $vm_name"
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

inject_key () {
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]]; then
    stop_vm "$vm_name"
    if [ -f "$ssh_key" ]; then
      if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
        execute_command "virt-customize -a $vm_disk --ssh-inject $vm_username:file:$ssh_key" "linuxsu"
      else
        verbose_message "VM disk \"$vm_disk\" does not exist" "warn"
      fi
    else
      verbose_message "SSH key file \"$ssh_key\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Upload file

upload_file () {
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]] || [ "$do_dryrun" = "true" ]; then
    if [ -f "$source_file" ]; then
      execute_command "chmod +x $source_file" ""
      if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
        execute_command "virt-customize -a $vm_disk --upload $source_file:$dest_file" "linuxsu"
      else
        verbose_message "VM disk \"$vm_disk\" does not exist" "warn"
      fi
    else
      verbose_message "Source file \"$source_file\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Run command

run_command () {
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]] || [ "$do_dryrun" = "true" ]; then
    if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
      stop_vm "$vm_name"
      execute_command "virt-customize -a $vm_disk --run-command '$vm_command'" "linuxsu"
    else
      verbose_message "VM disk \"$vm_disk\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Set password

set_password () {
  vm_command="virt-customize -a $vm_disk --root-password password:$vm_password" 
  run_command "$vm_command"
}

# Customize VM

customize_vm () {
  vm_name="$1"
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]] || [ "$do_dryrun" = "true" ]; then
    stop_vm "$vm_name"
    if [ -f "$post_script" ] || [ "$do_dryrun" = "true" ]; then
      execute_command "virt-customize " "linuxsu"
    else
      verbose_message "Post install script \"$post_script\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Print contents of file

print_contents () {
  file_name="$1" 
  if [ -f "$file_name" ]; then
    if [ "$do_verbose" = "true" ]; then
      verbose_message "Contents of file \"$file_name\"" "info"
      cat "$file_name"
    fi
  fi
}

# Configure network

configure_network () {
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]] || [ "$do_dryrun" = "true" ]; then
    stop_vm "$vm_name"
    temp_file="/tmp/01-netcfg.yaml"
    echo "network"                                 > "$temp_file"
    echo "  ethernets:"                           >> "$temp_file"
    echo "    $vm_net_dev:"                       >> "$temp_file"
    echo "      dhcp4: $vm_dhcp"                  >> "$temp_file"
    if [ "$vm_dhcp" = "false" ]; then
      echo "      addresses: [$vm_ip/$vm_cidr]"   >> "$temp_file"
      echo "      nameservers: [$vm_dns]"         >> "$temp_file"
      echo "    routes:"                          >> "$temp_file"
      echo "      - to: default"                  >> "$temp_file"
      echo "        via: $vm_gateway"             >> "$temp_file"
    fi
    echo "  version: 2"                           >> "$temp_file"
    source_file="$temp_file"
    touch "$source_file"
    chmod 700 "$source_file"
    print_contents "$source_file" 
    dest_file="/etc/netplan/01-netcfg.yaml"
    upload_file
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Set VM hostname

set_hostname () {
  if [ "$vm_fqdn" = "" ]; then
    if [ "$vm_domain" = "" ]; then
      vm_fqdn="$vm_hostname"
    else
      vm_fqdn="$vm_hostname.$vm_domain"
    fi
  fi
  vm_command="hostnamectl set-hostname $vm_fqdn"
  run_command "$vm_command"
}

install_packages () {
  vm_check=$(virsh list --all |grep -c $vm_name )
  if [[ "$vm_check" = "1" ]] || [ "$do_dryrun" = "true" ]; then
    if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
      execute_command "virt-customize -a $vm_disk --install '$vm_packages'" "linuxsu"
    else
      verbose_message "VM disk \"$vm_disk\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
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
  if [ "$do_debug" = "true" ]; then
    set -x
  fi
  verbose_message "Enabling debug mode" "notice"
  if [ "$do_strict" = "true" ]; then
    set -u
  fi
  verbose_message "Enabling strict mode" "notice"
  if [ "$vm_arch" = "" ]; then
    vm_arch="$os_arch"
  fi
  verbose_message "Setting VM arch to \"$vm_arch\"" "notice"
  if [ "$vm_cputype" = "" ]; then
    if [ "$os_name" = "Darwin" ]; then
      if [ "$os_arch" = "arm64" ]; then
        vm_cputype="cortex-a57"
      else
        vm_cputype="host"
      fi
    else
      vm_cputype="host"
    fi
  fi
  verbose_message "Setting CPU type to \"$vm_cputype\"" "notice"
  if [ "$vm_name" = "" ]; then
    vm_name="$script_name"
  fi
  if [ "$vm_cpus" = "" ]; then
    vm_cpus="2"
  fi
  verbose_message "Setting VM CPUs to \"$vm_cpus\"" "notice"
  if [ "$vm_ram" = "" ]; then
    vm_ram="4096"
  fi
  verbose_message "Setting VM name to \"$vm_ram\"" "notice"
  if [ "$vm_size" = "" ]; then
    vm_size="20G"
  fi
  verbose_message "Setting VM size to \"$vm_size\"" "notice"
  if [ "$os_vers" = "" ]; then
    os_vers="24.04"
  fi
  verbose_message "Setting OS version to \"$os_vers\"" "notice"
  if [ "$vm_boot" = "" ]; then
    vm_boot="uefi"
  fi
  verbose_message "Setting VM boot type to \"$vm_boot\"" "notice"
  if [ "$vm_graphics" = "" ]; then
    vm_graphics="none"
  fi
  verbose_message "Setting VM vm_graphics to \"$vm_graphics\"" "notice"
  if [ "$vm_hostname" = "" ]; then
    vm_hostname="$script_name"
  fi
  verbose_message "Setting VM hostname to \"$vm_hostname\"" "notice"
  if [ "$vm_net_type" = "" ]; then
    vm_net_type="bridge"
  fi
  verbose_message "Setting VM network type to \"$vm_net_type\"" "notice"
  if [ "$os_name" = "Darwin" ]; then
    vm_bridge="en0"
  else
    vm_bridge="br0"
  fi
  verbose_message "Setting VM bridge to \"$vm_bridge\"" "notice"
  if [ "$vm_net_bus" = "" ]; then
    vm_net_bus="virtio"
  fi
  verbose_message "Setting VM network driver/bus to \"$vm_net_bus\"" "notice"
  if [ "$vm_net_dev" = "" ]; then
    vm_net_dev="enp1s0"
  fi
  verbose_message "Setting VM network device to \"$vm_net_dev\"" "notice"
  if [ "$vm_cidr" = "" ]; then
    vm_cidr="24"
  fi
  verbose_message "Setting VM CIDR to \"$vm_cidr\"" "notice"
  if [ "$vm_dns" = "" ]; then
    vm_dns="8.8.8.8"
  fi
  verbose_message "Setting VM DNS server to \"$vm_dns\"" "notice"
  if [ "$image_file" = "" ]; then
    image_file="ubuntu-$os_vers-server-cloudimg-$os_arch.img"
  fi
  verbose_message "Setting Cloud Image file to \"$image_file\"" "notice"
  if [ "$image_url" = "" ]; then
    image_url="https://cloud-images.ubuntu.com/releases/$os_vers/release/$image_file"
  fi
  verbose_message "Setting Cloud Image URL to \"$image_url\"" "notice"
  if [ "$os_name" = "Darwin" ]; then
    brew_dir="/opt/homebrew/Cellar"
    if [ ! -d "$brew_dir" ]; then
      brew_dir="/usr/local/Cellar"
    fi
    verbose_message "Setting brew directory to \"$brew_dir\"" "notice"
  fi
  if [ "$virt_dir" = "" ]; then
    if [ "$os_name" = "Darwin" ]; then
      virt_dir="$brew_dir/libvirt"
    else
      virt_dir="/var/lib/libvirt"
    fi
  fi
  verbose_message "Setting libvirt directory to \"$virt_dir\"" "notice"
  if [ "$image_dir" = "" ]; then
    image_dir="$virt_dir/images"
  fi
  verbose_message "Setting Image directory to \"$image_dir\"" "notice"
  if [ "$vm_disk" = "" ]; then
    vm_disk="$image_dir/$vm_name/$vm_name.qcow2"
  fi
  verbose_message "Setting VM disk to \"$vm_disk\"" "notice"
  if [ "$pool_name" = "" ]; then
    pool_name="$vm_name"
  fi
  verbose_message "Setting pool name to \"$pool_name\"" "notice"
  if [ "$pool_dir" = "" ]; then
    pool_dir="$image_dir/$pool_name"
  fi
  verbose_message "Setting pool directory to \"$pool_dir\"" "notice"
  if [ "$release_dir" = "" ]; then
    release_dir="$image_dir/releases"
  fi
  verbose_message "Setting release directory to \"$release_dir\"" "notice"
  if [ "$vm_osvariant" = "" ]; then
    vm_osvariant="ubuntu$os_vers"
  fi
  verbose_message "Setting VM OS variant to \"$vm_osvariant\"" "notice"
  if [ "$post_script" = "" ]; then
    post_script="$script_dir/scripts/post_install.sh"
  fi
  verbose_message "Setting post install script to \"$post_script\"" "notice"
  if [ "$cache_dir" = "" ]; then
    cache_dir="$os_home/.cache/virt-manager"
  fi
  verbose_message "Setting cache directory to \"$cache_dir\"" "notice"
  if [ "$vm_username" = "" ]; then
    if [ "$do_password" = "true" ]; then
      vm_username="root"
    else
      vm_username="ubuntu"
    fi
  fi
  verbose_message "Setting username to \"$vm_username\"" "notice"
  if [ "$vm_password" = "" ]; then
    vm_password="ubuntu"
  fi
  verbose_message "Setting password to \"$vm_password\"" "notice"
  if [ "$ssh_key" = "" ]; then
    ssh_key="$os_home/.ssh/id_rsa.pub"
  fi
  verbose_message "Setting SSH key to \"$ssh_key\"" "notice"
  if [ "$vm_ip" = "dhcp" ]; then
    verbose_message "Setting network to DHCP" "notice"
  else
    if [ ! "$vm_ip" = "" ]; then
      verbose_message "Setting network to static"     "notice"
      verbose_message "Seting IP to $vm_ip"           "notice"
      verbose_message "Seting CIDR to $vm_cidr"       "notice"
      verbose_message "Seting gateway to $vm_gateway" "notice"
      verbose_message "Seting DNS server to $vm_dns"  "notice"
    fi
  fi
  create_libvirt_dir "$release_dir"
}

# Process action

process_actions () {
  actions="$1"
  case $actions in
    action|help)      # action
      # Print actions help
      print_usage "actions"
      exit
      ;;
    *config)          # action
      # Check config
      do_check_config="true"
      ;;
    connect|console)  # action
      # Connect to VM
      do_connect="true"
      ;;
    copy|upload)      # action
      # Copy file to VM
      do_upload="true"
      ;;
    createpool)       # action
      # Create pool
      do_create_pool="true"
      ;;
    createvm)         # action
      # Create VM
      do_get_image="true"
      do_check_config="true"
      do_create_pool="true"
      do_create_vm="true"
      ;;
    *network*)        # action
      # Configure network
      do_network="true"
      ;;
    customize|post*)  # action
      # Do postinstall config
      do_post="true"
      ;;
    deletepool)       # action
      # Create pool
      do_delete_pool="true"
      ;;
    deletevm)         # action
      # Create VM
      do_check_config="true"
      do_delete_pool="true"
      do_delete_vm="true"
      ;;
    getimage)         # action
      # Get image
      do_get_image="true"
      ;; 
    *host*)
      # Set VM hostname
      do_hostname="true"
      ;;
    *inject*)         # action
      # Inject SSH key
      do_inject_key="true"
      ;;
    install*)         # action
      # Install packages in VM
      do_install="true"
      ;;
    listvm*)          # action
      # List VMs
      do_list_vms="true"
      ;;
    listpool*)        # action
      # List pools
      do_list_pools="true"
      ;;
    listnet*)         # action
      # List nets
      do_list_nets="true"
      ;;
    *password*)       # action
      # Set password for user in VM
      do_password="true"
      ;;
    run*)             # action
      # Run command in VM
      do_command="true"
      ;;
    shellcheck)       # action
      # Check script with shellcheck
      do_shellcheck="true"
      ;;
    shutdown*|stop*)  # action
      # Stop VM
      do_stop_vm="true"
      ;;
    start*|boot*)     # action
      # Start VM
      do_start_vm="true"
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
  options="$1"
  case $options in
    debug)          # option
      # Enable debug mode
      do_debug="true"
      ;;
    dryrun)         # option
      # Enable dryrun mode
      do_dryrun="true"
      ;;
    dhcp)           # option
      # Use DHCP
      vm_dhcp="true"
      ;;
    noautoconsole)  # option
      # Disable autoconsole
      do_autoconsole="false"
      ;;
    autoconsole)    # option
      # Enable autoconsole
      do_autoconsole="true"
      ;;
    noautostart)    # option
      # Disable autoconsole
      do_autostart="false"
      ;;
    autostart)      # option
      # Enable autoconsole
      do_autostart="true"
      ;;
    nobacking)      # option
      # Enable strict mode
      do_backing="false"
      ;;
    options|help)   # option
      # Print options help
      print_usage "options"
      exit
      ;;
    noreboot)       # option
      # Disable reboot
      do_reboot="false"
      ;;
    reboot)         # option
      # Disable reboot
      do_reboot="true"
      ;;
    strict)         # option
      # Enable strict mode
      do_strict="true"
      ;;
    verbose)        # option
      # Enable verbose mode
      do_verbose="true"
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
}

# Set defaults

set_defaults

# Handle verbose and debug early so it's enabled early

if [[ "$*" =~ "strict" ]]; then
  do_verbose="true"
  set -u
fi

if [[ "$*" =~ "debug" ]]; then
  do_verbose="true"
  set -x
fi

if [[ "$*" =~ "verbose" ]]; then
  do_verbose="true"
fi

# Handle commandline arguments

while test $# -gt 0; do
  case $1 in
    --action)             # switch
      # Action to perform
      check_value "$1" "$2"
      actions="$2"
      do_actions="true"
      shift 2
      ;;
    --actions)            # switch
      # Print actions
      print_usage "actions"
      shift
      exit
      ;;
    --arch)               # switch
      # Specify architecture
      check_value "$1" "$2"
      vm_arch="$2"
      shift 2
      ;;
    --boot*)              # switch
      # VM boot type (e.g. UEFI)
      check_value "$1" "$2"
      vm_boot="$2"
      shift 2
      ;;
    --bridge)             # switch
      # VM network bridge
      check_value "$1" "$2"
      vm_bridge="$2"
      shift 2
      ;;
    --checkconfig)        # switch
      # Check config
      do_check_config="true"
      shift
      ;;
    --cidr)               # switch
      # VM CIDR
      check_value "$1" "$2"
      vm_cidr="$2"
      shift 2
      ;;
    --cpus)               # switch
      # Number of VM CPUs
      check_value "$1" "$2"
      vm_cpus="$2"
      shift 2
      ;;
    --cputype)            # switch
      # Number of VM CPUs
      check_value "$1" "$2"
      vm_cputype="$2"
      shift 2
      ;;
    --debug)              # switch
      # Run in debug mode
      do_debug="true"
      shift
      ;;
    --dest*)              # switch
      # Destination of file to copy into VM disk
      check_value "$1" "$2"
      dest_file="$2"
      shift 2
      ;;
    --disk)               # switch
      # VM disk file
      check_value "$1" "$2"
      vm_disk="$2"
      shift 2
      ;;
    --dns)                # switch
      # VM DNS server
      check_value "$1" "$2"
      vm_dns="$2"
      shift 2
      ;;
    --domain@)            # switch
      # VM domainname
      check_value "$1" "$2"
      vm_domain="$2"
      shift 2
      ;;
    --dryrun)             # switch
      # Run in dryrun mode
      do_dryrun="true"
      shift
      ;;
    --force)              # switch
      # Force mode
      do_force="true"
      shift
      ;;
    --fqdn)               # switch
      # VM FQDN
      check_value "$1" "$2"
      vm_fqdn="$2"
      shift 2
      ;;
    --getimage)           # switch
      # Get Image
      do_get_image="true"
      shift
      ;;
    --gateway|--router)   # switch
      # VM gateway address
      check_value "$1" "$2"
      vm_gateway="$2"
      shift 2
      ;;
    --graphics)           # switch
      # VM Graphics type
      check_value "$1" "$2"
      vm_graphics="$2"
      shift 2
      ;;
    --help|--usage|-h)    # switch
      # Print help
      print_usage "$2"
      shift 2
      exit
      ;;
    --hostname)           # switch
      # VM hostname 
      check_value "$1" "$2"
      vm_hostname="$2"
      shift 2
      ;;
    --imagedir)           # switch
      # Image directory
      check_value "$1" "$2"
      image_dir="$2"
      shift 2
      ;;
    --imagefile)          # switch
      # Image file
      check_value "$1" "$2"
      image_file="$2"
      shift 2
      ;;
    --imageurl)           # switch
      # Image URL
      check_value "$1" "$2"
      image_url="$2"
      shift 2
      ;;
    --ip*)                # switch
      # VM IP address
      check_value "$1" "$2"
      vm_ip="$2"
      shift 2
      ;;
    --name|--vmname)      # switch
      # Name of VM
      check_value "$1" "$2"
      vm_name="$2"
      shift 2
      ;;
    --nettype)            # switch
      # Net type (e.g. bridge)
      check_value "$1" "$2"
      vm_net_type="$2"
      shift 2
      ;;
    --netbus|netdriver)   # switch
      # Net bus/driver (e.g. virtio)
      check_value "$1" "$2"
      vm_net_bus="$2"
      shift 2
      ;;
    --netdev|--nic)       # switch
      # VM network device (e.g. enp1s0)
      check_value "$1" "$2"
      vm_net_dev="$2"
      shift 2
      ;;
    --options)            # switch
      # Options
      check_value "$1" "$2"
      options="$2"
      do_options="true"
      shift 2
      ;;
    --osvariant)          # switch
      # Os variant
      check_value "$1" "$2"
      vm_osvariant="$2"
      shift 2
      ;;
    --osvers)             # switch
      # OS version of image
      check_value "$1" "$2"
      os_vers="$2"
      shift 2
      ;;
    --packages)           # switch
      # Packages to install in VM
      check_value "$1" "$2"
      vm_packages="$2"
      shift 2
      ;;
    --password)           # switch
      # Password for user (e.g. root)
      check_value "$1" "$2"
      vm_password="$2"
      shift 2
      ;;
    --poolname)           # switch
      # Pool name
      check_value "$1" "$2"
      pool_name="$2"
      shift 2
      ;;
    --pooldir)            # switch
      # Pool directory
      check_value "$1" "$2"
      pool_dir="$2"
      shift 2
      ;;
    --post*)              # switch
      # Post install script
      check_value "$1" "$2"
      post_script="$2"
      shift 2
      ;;
    --ram)                # switch
      # Amount of VM RAM
      check_value "$1" "$2"
      vm_ram="$2"
      shift 2
      ;;
    --run*)               # swith
      # Command to run in VM image
      check_value "$1" "$2"
      vm_command="$2"
      shift 2
      ;;
    --size)               # switch
      # Size of VM disk
      check_value "$1" "$2"
      vm_size="$2"
      shift 2
      ;;
    --shellcheck)         # switch
      # Run shellcheck on script
      do_shellcheck="true"
      shift
      ;;
    --source*)            # switch
      # Source file to copy into VM disk
      check_value "$1" "$2"
      source_file="$2"
      shift 2
      ;;
    --sshkey)             # switch
      # SSH username
      check_value "$1" "$2"
      ssh_key="$2"
      shift 2
      ;;
    --strict)             # switch
      # Run in strict mode
      do_strict="true"
      shift
      ;;
    --user*)              # switch
      # Username
      check_value "$1" "$2"
      vm_username="$2"
      shift 2
      ;;
    --verbose)            # switch
      # Run in verbose mode
      do_verbose="true"
      shift
      ;;
    --version|-V)         # switch
      # Print version
      print_version
      shift
      exit
      ;;
    --virtdir)            # switch
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
      print_usage ""
      exit
      ;;
  esac
done

if [ "$do_shellcheck" = "true" ]; then
  check_shellcheck
  exit
fi
if [ "$do_actions" = "true" ]; then
  process_actions "$actions"
fi

reset_defaults

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
if [ "$do_start_vm" = "true" ]; then
  start_vm "$vm_name"
fi
if [ "$do_stop_vm" = "true" ]; then
  stop_vm "$vm_name"
fi
if [ "$do_delete_vm" = "true" ]; then
  delete_vm
fi
if [ "$do_delete_pool" = "true" ]; then
  delete_pool "$pool_name"
fi
if [ "$do_connect" = "true" ]; then
  connect_to_vm "$vm_name"
fi
if [ "$do_post" = "true" ]; then
  customize_vm $vm_name
fi
if [ "$do_list_vms" = "true" ]; then
  list_vms
fi
if [ "$do_list_pools" = "true" ]; then
  list_pools
fi
if [ "$do_list_nets" = "true" ]; then
  list_nets
fi
if [ "$do_inject_key" = "true" ]; then
  inject_key
fi
if [ "$do_upload" = "true" ]; then
  upload_file
fi
if [ "$do_command" = "true" ]; then
  run_command
fi
if [ "$do_password" = "true" ]; then
  set_password
fi
if [ "$do_network" = "true" ]; then
  configure_network
fi
if [ "$do_hostname" = "true" ]; then
  set_hostname
fi
if [ "$do_install" = "true" ]; then
  install_packages
fi
