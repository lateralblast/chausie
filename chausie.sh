#!/usr/bin/env bash

# Name:         chausie (Cloud-Image Host Automation Utility and System Image Engine)
# Version:      0.7.5
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
# shellcheck disable=SC2129

# Set/get some environment parameters

script_args="$*"
script_file="$0"
script_name="chausie"
script_file=$( realpath "$script_file" )
script_path=$( dirname "$script_file" )
module_path="$script_path/modules"
script_bin=$( basename "$script_file" )
os_name=$( uname )
os_arch=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
os_user=$( whoami )
os_group=$( id -gn )
os_home="$HOME"
mod_path="$script_path/modules"

export LIBGUESTFS_BACKEND=direct

# Print help

print_help () {
  script_help=$( grep -A1 "# switch" "$script_file" |sed "s/^--//g" |sed "s/# switch//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/ /g" | sed "/^\s*$/d" )
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
  script_actions=$( grep -A1 "# action" "$script_file" |sed "s/^--//g" |sed "s/# action//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/ /g" |sed "/^\s*$/d" )
  echo "Actions:"
  echo "-------"
  echo "$script_actions"
  echo ""
}

# Print options

print_options () {
  script_options=$( grep -A1 "# option" "$script_file" |sed "s/^--//g" |sed "s/# option//g" | tr -s " " |grep -Ev "=|echo" |sed "s/#/ /g" |sed "/^\s*$/d" )
  echo "Options:"
  echo "-------"
  echo "$script_options"
  echo ""
}

# Print Usage

print_usage () {
  usage="$1"
  case $usage in
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
  script_vers=$( grep '^# Version' < "$0" | awk '{print $3}' )
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
        execute_command "apt-get install -y $package" "su"
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

# Get DNS

get_dns () {
  if [ "$os_name" = "Darwin" ]; then
    vm_dns=$( scutil --dns | grep nameserver |head -1 |awk '{print $3}' )
  else
    vm_dns=$( resolvectl |grep "DNS Servers" |head -1 |awk '{print $3}' )
    if [ "$vm_dns" = "" ]; then
      vm_dns=$( resolvectl |grep "Current DNS" |awk '{print $4}' )
    fi
  fi
}

# Get gateway

get_gateway () {
  if [ "$os_name" = "Darwin" ]; then
    vm_gateway=$( route -n get default |grep gateway |awk '{print $2}' )
  else
    vm_gateway=$( ip r |grep default |awk '{print $3}' )
  fi
}

# Get cidr

get_cidr () {
  if [ "$os_name" = "Darwin" ]; then
    bin_test=$( command -v ipcalc | grep -c ipcalc )
    if [ ! "$bin_test" = "0" ]; then
      interface=$( route -n get default |grep interface |awk '{print $2}' )
      vm_netmask=$( ifconfig "$interface" |grep mask |awk '{print $4}' )
      vm_cidr=$( ipcalc "1.1.1.1" "$vm_netmask" | grep ^Netmask |awk '{print $4}' )
    else
      verbose_message "Tool ipcalc not found" "warn"
      vm_cidr="24"
    fi
  else
    vm_cidr=$( ip r |grep link|awk '{print $1}' |cut -f2 -d/ )
    if [[ "$vm_cidr" =~ "." ]] || [ "$vm_cidr" = "" ]; then
      vm_netmask=$( route -n |awk '{print $3}' |grep "^255" )
      vm_cidr=$( ipcalc "1.1.1.1" "$vm_netmask" | grep ^Netmask |awk '{print $4}' )
    fi
  fi
}

# Check VM name

check_vm_name () {
  if [ "$vm_name" = "" ]; then
    verbose_message "VM name is not set" "warn"
    do_exit
  fi
  if [ "$vm_name" = "$script_name" ]; then
    verbose_message "VM name is set to default" "warn"
    if [ "$do_force" = "false" ]; then
      do_exit
    fi
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
  ssh_key_file=""
  do_actions="false"
  do_options="false"
  do_verbose="false"
  do_strict="false"
  do_dryrun="false"
  do_debug="false"
  do_force="false"
  do_shellcheck="false"
  do_backing="true"
  do_autoconsole="false"
  do_autostart="false"
  do_reboot="false"
  do_localds="true"
  do_mask="false"
  vm_dhcp="false"
  vm_lock="false"
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
  vm_userid=""
  vm_groupname=""
  vm_groupid=""
  vm_password=""
  vm_net_type=""
  vm_net_bus=""
  vm_net_dev=""
  vm_net_cfg=""
  vm_init_cfg=""
  vm_cdrom=""
  vm_cidr=""
  vm_dns=""
  vm_ip=""
  vm_shell=""
  vm_gateway=""
  vm_bridge=""
  vm_cputype=""
  vm_hostname=""
  vm_domain=""
  vm_fqdn=""
  vm_gecos=""
  vm_crypt=""
  vm_power=""
  vm_home_dir=""
  vm_sudoers=""
  vm_netmask=""
  vm_file_perms=""
  vm_file_owner=""
  vm_file_group=""
  vm_packages=""
  vm_machine=""
  vm_host_device=""
  source_file=""
  dest_file=""
  post_script=""
  cache_dir=""
  virt_dir=""
  libvirt_groups="kvm libvirt libvirt-qemu"
  if [ "$os_name" = "Darwin" ]; then
    installed_packages=$( brew list )
    required_packages="qemu libvirt libvirt-glib libvirt-python virt-manager libosinfo ipcalc cdrtools"
  else
    vm_bridge="br0"
    installed_packages=$( dpkg -l |grep ^ii |awk '{print $2}' )
    required_packages="virt-manager libosinfo-bin libguestfs-tools cloud-image-utils ipcalc"
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
      command="sudo sh -c \"$command\""
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

if [ -d "$module_path" ]; then
  modules=$( find "$module_path" -name "*.sh" )
  for module in $modules; do
    if [[ "$script_args" =~ "verbose" ]]; then
     verbose_message "Module $module" "load"
    fi
    . "$module"
  done
fi

# Check config

check_config () {
  verbose_message "Checking config" "info"
  for check_dir in $virt_dir $image_dir $cache_dir; do
    verbose_message "Checking directory \"$check_dir\" exists" "info"
    if [ ! -d "$check_dir" ]; then
      verbose_message "Creating directory \"$check_dir\"" "notice"
      execute_command "mkdir -p $check_dir" "linuxsu"
    fi
  done
  if [ "$os_name" = "Linux" ]; then
    verbose_message "Checking group permissions on \"/dev/kvm\"" "info"
    group_check=$( sudo stat -c "%G" "/dev/kvm" )
    if [ ! "$group_check" = "kvm" ]; then
      verbose_message "Fixing group permissions on \"/dev/kvm\"" "notice"
      execute_command "chown root:kvm /dev/kvm" "su"
    fi
    verbose_message "Checking permissions on \"$image_dir\"" "info"
    perms_check=$( sudo stat -c "%a" "$image_dir" )
    if [ ! "$perms_check" = "775" ]; then
      verbose_message "Fixing permissions on \"$image_dir\"" "notice"
      execute_command "chmod -R 775 $image_dir" "su"
    fi
    for group in $libvirt_groups; do
      verbose_message "Checking user \"$os_user\" is a member of a group \"$group\"" "info"
      group_check=$( groups |grep -c "$group " )
      if [ "$group_check" = "0" ]; then
        verbose_message "Adding user \"$os_user\" to group \"$group\"" "notice"
        execute_command "usermod -a -G $group $os_user" "su"
      fi
    done
  fi
  check_packages
  if [ "$os_name" = "Darwin" ]; then
    localds_bin="/usr/local/bin/cloud-localds"
    localds_url="https://raw.githubusercontent.com/canonical/cloud-utils/main/bin/cloud-localds"
    if [ ! -f "$localds_bin" ]; then
      execute_command "curl -o $localds_bin $localds_url" "su"
      execute_command "chmod +x $localds_bin" "su"
    fi
  fi
}

# Fix Linux libvirt perms

fix_libvirt_perms () {
  file_name="$1"
  if [ "$os_name" = "Linux" ]; then
    execute_command "chown root:libvirt-qemu $file_name" "su"
    execute_command "chmod 775 $file_name" "su"
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
  create_libvirt_dir "$pool_dir"
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ ! "$pool_test" =~ $pool_name ]]; then
    execute_command "virsh pool-create-as --name $pool_name --type dir --target $pool_dir > /dev/null 2>&1" ""
    fix_libvirt_perms "$pool_dir"

  else
    verbose_message "Pool \"$pool_name\" already exists" "notice"
  fi
}

# Delete Pool

delete_pool () {
  pool_test=$( virsh pool-list |awk "{ print \$1 }" )
  if [[ "$pool_test" =~ $pool_name ]]; then
    execute_command "virsh pool-destroy --pool $pool_name > /dev/null 2>&1" ""
  else
    verbose_message "Pool \"$pool_name\" does not exist" "notice"
  fi
  delete_libvirt_dir "$pool_dir"
}

# Check VM bridge

check_bridge () {
  if [ "$os_name" = "Linux" ]; then
    bridge_check=$( ip link show $vm_bridge 2>&1 |grep "does not exist" |wc -c )
    if [ ! "$bridge_check" = "0" ]; then
      verbose_message "Bridge device \"$vm_bridge\" does not exist" "warn"
      do_exit
    fi
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
    execute_command "cp $release_dir/$image_file $vm_disk" "linuxsu"
    execute_command "qemu-img resize $vm_disk $vm_size" "linuxsu"
  fi
}

# Create VM

create_vm () {
  check_vm_name
  check_bridge
  check_image_exists
  check_disk_exists
  create_disk
  fix_libvirt_perms "$vm_disk"
  if [ "$do_localds" = "true" ]; then
    configure_network
    configure_init
    if [ "$os_name" = "Linux" ]; then
      execute_command "cloud-localds --network-config $vm_net_cfg $vm_cdrom $vm_init_cfg" "linuxsu"
    else
      execute_command "mkisofs -output $vm_cdrom -volid cidata -joliet -rock {$vm_init_cfg,$vm_net_cfg}"
    fi
  fi
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
  if [ "$do_localds" = "true" ]; then
    cli_disk="--disk $vm_disk,format=qcow2,bus=virtio --disk $vm_cdrom,device=cdrom"
  else
    cli_disk="--disk $vm_disk,format=qcow2,bus=virtio"
  fi
  if [ "$os_name" = "Darwin" ]; then
    cli_network=""
  else
    cli_network="--network $vm_net_type=$vm_bridge,model=virtio"
  fi
  cli_osvariant="--os-variant $vm_osvariant"
  if [ "$vm_host_device" = "" ]; then
    cli_hostdevice=""
  else
    cli_hostdevice="--host-device $vm_host_device"
  fi
  if [ "$vm_features" = "" ]; then
    cli_features=""
  else
    cli_features="--features $vm_features"
  fi
  cli_graphics="--graphics $vm_graphics"
  cli_boot="--boot $vm_boot"
  if [ "$do_reboot" = "false" ]; then
    cli_reboot="--noreboot"
  fi
  command="virt-install --import $cli_name $cli_memory $cli_vcpus $cli_cpu $cli_disk $cli_network $cli_osvariant $cli_autoconsole $cli_graphics $cli_boot $cli_autostart $cli_reboot $cli_hostdevice $cli_features"
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ "$vm_check" = "0" ]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" already exists" "notice"
  fi
  if [ "$do_localds" = "false" ]; then
    create_keys
  fi
}

# Delete VM

delete_vm () {
  check_vm_name
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ ! "$vm_check" = "0" ]; then
    stop_vm
    execute_command "virsh undefine --nvram $vm_name > /dev/null 2>&1" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "notice"
  fi
}

# Start VM

start_vm () {
  check_vm_name
  command="virsh start $vm_name"
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ ! "$vm_check" = "0" ]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Stop VM

stop_vm () {
  check_vm_name
  command="virsh shutdown $vm_name"
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ ! "$vm_check" = "0" ]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Connect to VM

connect_to_vm () {
  check_vm_name
  command="virsh console $vm_name"
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ ! "$vm_check" = "0" ]; then
    execute_command "$command" "linuxsu"
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# SSH to vm

ssh_to_vm () {
  if [ "$vm_ip" = "" ]; then
    verbose_message "No IP given to SSH to" "warn"
    do_exit
  else
    execute_command "ssh -oStrictHostKeyChecking=no $vm_username@$vm_ip"
  fi
}

# Inject SSH key

inject_key () {
  check_vm_name
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ "$vm_check" = "1" ]; then
    stop_vm
    if [ -f "$ssh_key_file" ]; then
      if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
        execute_command "virt-customize -a $vm_disk --ssh-inject $vm_username:file:$ssh_key_file" "linuxsu"
      else
        verbose_message "VM disk \"$vm_disk\" does not exist" "warn"
      fi
    else
      verbose_message "SSH key file \"$ssh_key_file\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

# Upload file

upload_file () {
  check_vm_name
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ "$vm_check" = "1" ] || [ "$do_dryrun" = "true" ]; then
    if [ -f "$source_file" ]; then
      if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
        execute_command "virt-customize -a $vm_disk --upload $source_file:$dest_file" "linuxsu"
        if [ ! "$vm_file_owner" = "" ]; then
          if [ ! "$vm_file_group" = "" ]; then
            vm_command="chown $vm_file_owner $dest_file"
          else
            vm_command="chown $vm_file_owner:$vm_file_group $dest_file"
          fi
          run_command
        fi
        if [ ! "$vm_file_perms" = "" ]; then
          vm_command="chmod $vm_file_perms $dest_file"
          run_command
        fi
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
  check_vm_name
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ "$vm_check" = "1" ] || [ "$do_dryrun" = "true" ]; then
    if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
      stop_vm
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
  execute_command "virt-customize -a $vm_disk --root-password password:$vm_password"
}

# Customize VM

customize_vm () {
  check_vm_name
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ "$vm_check" = "1" ] || [ "$do_dryrun" = "true" ]; then
    stop_vm
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

# Generate password crypt/hash

generate_crypt () {
  if [ "$vm_crypt" = "" ]; then
    if [ "$os_name" = "Darwin" ]; then
      vm_crypt=$( echo -n "$vm_password" |openssl sha512 | awk '{ print $2 }' )
    else
      vm_crypt=$( echo "$vm_password" |mkpasswd --method=SHA-512 --stdin )
    fi
  fi
}

# Configure cloud-init config file

configure_init () {
  temp_file="/tmp/cloud-init.cfg"
  mask_file="/tmp/cloud-init.cfg.masked"
  generate_crypt
  echo "#cloud-config"                    |tee "$mask_file" > "$temp_file"
  echo "hostname: $vm_hostname"           |tee -a "$mask_file" >> "$temp_file"
  echo "groups:"                          |tee -a "$mask_file" >> "$temp_file"
  echo "  - $vm_groupname: $vm_username"  |tee -a "$mask_file" >> "$temp_file"
  echo "users:"                           |tee -a "$mask_file" >> "$temp_file"
  echo "  - default"                      |tee -a "$mask_file" >> "$temp_file"
  echo "  - name: $vm_username"           |tee -a "$mask_file" >> "$temp_file"
  echo "    gecos: $vm_gecos"             |tee -a "$mask_file" >> "$temp_file"
  echo "    primary_group: $vm_groupname" |tee -a "$mask_file" >> "$temp_file"
  echo "    groups: $vm_groups"           |tee -a "$mask_file" >> "$temp_file"
  echo "    shell: $vm_shell"             |tee -a "$mask_file" >> "$temp_file"
  echo "    passwd: \"#MASKED#\""                              >> "$mask_file"
  echo "    passwd: \"$vm_crypt\""                             >> "$temp_file"
  if [ ! "$ssh_key" = "" ]; then
    echo "    ssh-authorized-keys:"       |tee -a "$mask_file" >> "$temp_file"
    echo "      - \"#MASKED#\""                                >> "$mask_file"
    echo "      - \"$ssh_key\""                                >> "$temp_file"
  fi
  echo "    sudo: $vm_sudoers"            |tee -a "$mask_file" >> "$temp_file"
  echo "    lock_passwd: $vm_lock"        |tee -a "$mask_file" >> "$temp_file"
  echo "packages:"                        |tee -a "$mask_file" >> "$temp_file"
  if [[ "$vm_packages" =~ "," ]]; then
    IFS="," read -r -a array <<< "$vm_packages"
    for vm_package in "${array[@]}"; do
      echo "  - $vm_package"              |tee -a "$mask_file" >> "$temp_file"
    done
  else
    echo "  - $vm_packages"               |tee -a "$mask_file" >> "$temp_file"
  fi
  echo "growpart:"                        |tee -a "$mask_file" >> "$temp_file"
  echo "  mode: auto"                     |tee -a "$mask_file" >> "$temp_file"
  echo "  devices: ['/']"                 |tee -a "$mask_file" >> "$temp_file"
  echo "power_state:"                     |tee -a "$mask_file" >> "$temp_file"
  echo "  mode: $vm_power"                |tee -a "$mask_file" >> "$temp_file"
  if [ "$do_mask" = "true" ]; then
    print_contents "$mask_file"
  else
    print_contents "$temp_file"
  fi
  execute_command "cp $temp_file $vm_init_cfg" "linuxsu"
}

# Configure network

configure_network () {
  check_vm_name
  temp_file="/tmp/01-netcfg.yaml"
  if [ "$do_localds" = "false" ]; then
    vm_check=$( virsh list --all |grep -c "$vm_name" )
    if [ "$vm_check" = "1" ] || [ "$do_dryrun" = "true" ]; then
      stop_vm
      echo "network:"                                > "$temp_file"
      echo "  ethernets:"                           >> "$temp_file"
      echo "    $vm_net_dev:"                       >> "$temp_file"
      echo "      dhcp4: $vm_dhcp"                  >> "$temp_file"
      if [ "$vm_dhcp" = "false" ]; then
        echo "      addresses: [$vm_ip/$vm_cidr]"   >> "$temp_file"
        echo "      nameservers:"                   >> "$temp_file"
        echo "        addresses: [$vm_dns]"         >> "$temp_file"
        echo "      routes:"                        >> "$temp_file"
        echo "      - to: default"                  >> "$temp_file"
        echo "        via: $vm_gateway"             >> "$temp_file"
      fi
      echo "  version: 2"                           >> "$temp_file"
      source_file="$temp_file"
      chmod 700 "$source_file"
      print_contents "$source_file"
      dest_file="/etc/netplan/01-netcfg.yaml"
      vm_file_perms="600"
      vm_file_owner="root"
      upload_file
      vm_command="sed -i \"s/#DNS=/DNS=$vm_dns/g\" /etc/systemd/resolved.conf"
      run_command
      vm_command="rm /etc/resolv.conf"
      run_command
      vm_command="echo \"nameserver $vm_dns\" > /etc/resolv.conf"
      run_command
    else
      verbose_message "VM \"$vm_name\" does not exist" "warn"
    fi
   else
     echo "ethernets:"                            > "$temp_file"
     echo "  $vm_net_dev:"                       >> "$temp_file"
     echo "    dhcp4: $vm_dhcp"                  >> "$temp_file"
     if [ "$vm_dhcp" = "false" ]; then
       echo "    addresses: [$vm_ip/$vm_cidr]"   >> "$temp_file"
       echo "    nameservers:"                   >> "$temp_file"
       echo "      addresses: [$vm_dns]"         >> "$temp_file"
       echo "    routes:"                        >> "$temp_file"
       echo "    - to: default"                  >> "$temp_file"
       echo "      via: $vm_gateway"             >> "$temp_file"
     fi
     echo "version: 2"                           >> "$temp_file"
     source_file="$temp_file"
     chmod 700 "$source_file"
     print_contents "$source_file"
     execute_command "cp $source_file $vm_net_cfg" "linuxsu"
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
  run_command
}

install_packages () {
  check_vm_name
  vm_check=$( virsh list --all |grep -c "$vm_name" )
  if [ "$vm_check" = "1" ] || [ "$do_dryrun" = "true" ]; then
    if [ -f "$vm_disk" ] || [ "$do_dryrun" = "true" ]; then
      execute_command "virt-customize -a $vm_disk --install '$vm_packages'" "linuxsu"
    else
      verbose_message "VM disk \"$vm_disk\" does not exist" "warn"
    fi
  else
    verbose_message "VM \"$vm_name\" does not exist" "warn"
  fi
}

add_group () {
  if [ "$vm_groupid" = "" ]; then
    vm_command="groupadd $vm_groupname"
  else
    vm_command="groupadd -g $vm_groupid $vm_groupname"
  fi
  run_command
}

add_user () {
  add_group
  if [ "$vm_userid" = "" ]; then
    vm_command="useradd -g $vm_groupname -s $vm_shell -m -d $vm_home_dir $vm_username"
  else
    vm_command="useradd -u $vm_userid -g $vm_groupname -s $vm_shell -m -d $vm_home_dir $vm_username"
  fi
  run_command
}

add_sudoers () {
  if [ "$source_file" = "" ]; then
    source_file="/tmp/sudoers.$vm_username"
    echo "$vm_username $vm_sudoers" > "$source_file"
  fi
  if [ "$dest_file" = "" ]; then
    dest_file="/etc/sudoers.d/$vm_username"
  fi
  vm_file_owner="root"
  vm_file_group="root"
  vm_file_perms="600"
  print_contents "$source_file"
  upload_file
}

# Create SSH server keys

create_keys () {
  stop_vm
  vm_command="ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -t ed25519  -N \"\""
  run_command
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
  if [ "$do_dryrun" = "true" ]; then
    verbose_message "Enabling dryrun mode" "notice"
  fi
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
  verbose_message "Setting VM name to \"$vm_name\"" "notice"
  if [ "$vm_cpus" = "" ]; then
    vm_cpus="2"
  fi
  verbose_message "Setting VM CPUs to \"$vm_cpus\"" "notice"
  if [ "$vm_ram" = "" ]; then
    vm_ram="4096"
  fi
  verbose_message "Setting VM RAM to \"$vm_ram\"" "notice"
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
    vm_hostname="$vm_name"
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
  if [ "$vm_gateway" = "" ]; then
    get_gateway
  fi
  verbose_message "Setting VM gateway to \"$vm_gateway\"" "notice"
  if [ "$vm_cidr" = "" ]; then
    get_cidr
  fi
  verbose_message "Setting VM CIDR to \"$vm_cidr\"" "notice"
  if [ "$vm_dns" = "" ]; then
    get_dns
  fi
  verbose_message "Setting VM DNS server to \"$vm_dns\"" "notice"
  if [ ! "$vm_host_device" = "" ]; then
    vm_features="kvm_hidden=on"
    verbose_message "Setting VM features to \"$vm_features\"" "notice"
  fi
  if [ ! "$vm_machine" = "" ]; then
    verbose_message "Setting VM machine type to \"$vm_machine\"" "notice"
  fi
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
  if [ "$do_localds" = "true" ]; then
    if [ "$vm_cdrom" = "" ]; then
      vm_cdrom="$image_dir/$vm_name/$vm_name.cloud.img"
    fi
    verbose_message "Setting VM cdrom to \"$vm_cdrom\"" "notice"
    if [ "$vm_net_cfg" = "" ]; then
      vm_net_cfg="$image_dir/$vm_name/$vm_name.network.cfg"
    fi
    verbose_message "Setting VM network config file to \"$vm_net_cfg\"" "notice"
    if [ "$vm_init_cfg" = "" ]; then
      vm_init_cfg="$image_dir/$vm_name/$vm_name.cloud.cfg"
    fi
    verbose_message "Setting VM cloud-init file to \"$vm_init_cfg\"" "notice"
    if [ "$vm_packages" = "" ]; then
      vm_packages="ansible"
    fi
    verbose_message "Setting VM packages \"$vm_init_cfg\"" "notice"
  fi
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
    post_script="$script_path/scripts/post_install.sh"
  fi
  verbose_message "Setting post install script to \"$post_script\"" "notice"
  if [ "$vm_power" = "" ]; then
    vm_power="reboot"
  fi
  verbose_message "Setting VM power state to \"$vm_power\"" "notice"
  if [ "$cache_dir" = "" ]; then
    cache_dir="$os_home/.cache/virt-manager"
  fi
  verbose_message "Setting cache directory to \"$cache_dir\"" "notice"
  if [ "$vm_username" = "" ]; then
    if [[ "$actions" =~ "password" ]]; then
      vm_username="root"
    else
      vm_username="cloudadmin"
    fi
  fi
  verbose_message "Setting username to \"$vm_username\"" "notice"
  if [ "$vm_password" = "" ]; then
    vm_password="cloudadmin"
  fi
  verbose_message "Setting password to \"$vm_password\"" "notice"
  if [ "$vm_userid" = "" ]; then
    vm_userid="1000"
  fi
  verbose_message "Setting user ID to \"$vm_userid\"" "notice"
  if [ "$vm_groupname" = "" ]; then
    vm_groupname="$vm_username"
  fi
  verbose_message "Setting group to \"$vm_groupname\"" "notice"
  if [ "$vm_gecos" = "" ]; then
    vm_gecos="${vm_username^}"
  fi
  verbose_message "Setting GECOS field to \"$vm_gecos\"" "notice"
  if [ "$vm_groupid" = "" ]; then
    vm_groupid="1000"
  fi
  verbose_message "Setting group ID to \"$vm_groupid\"" "notice"
  if [ "$vm_home_dir" = "" ]; then
    vm_home_dir="/home/$vm_username"
  fi
  verbose_message "Setting home directory to \"$vm_home_dir\"" "notice"
  if [ "$vm_groups" = "" ]; then
    vm_groups="users"
  fi
  verbose_message "Setting groups to \"$vm_groups\"" "notice"
  if [ "$vm_shell" = "" ]; then
    vm_shell="/usr/bin/bash"
  fi
  verbose_message "Setting shell to \"$vm_shell\"" "notice"
  if [ "$vm_sudoers" = "" ]; then
    vm_sudoers="ALL=(ALL) NOPASSWD:ALL"
  fi
  verbose_message "Setting sudoers entry to \"$vm_sudoers\"" "notice"
  if [ "$ssh_key_file" = "" ]; then
    ssh_key_file=$( find "$os_home/.ssh" -name "*.pub" |head -1 )
  fi
  verbose_message "Setting SSH key file to \"$ssh_key_file\"" "notice"
  if [ "$ssh_key" = "" ]; then
    if [ ! "$ssh_key_file" = "" ]; then
      ssh_key=$( cat "$ssh_key_file" )
    fi
  fi
  verbose_message "Setting SSH key to \"$ssh_key\"" "notice"
  if [ "$vm_ip" = "dhcp" ] || [ "$vm_ip" = "" ]; then
    vm_dhcp="true"
    verbose_message "Setting network to DHCP" "notice"
  else
    verbose_message "Setting network to static"     "notice"
    verbose_message "Seting IP to $vm_ip"           "notice"
    verbose_message "Seting CIDR to $vm_cidr"       "notice"
    verbose_message "Seting gateway to $vm_gateway" "notice"
    verbose_message "Seting DNS server to $vm_dns"  "notice"
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
    *password*)       # action
      # Set password for user in VM image
      set_password
      ;;
    run*)             # action
      # Run command in VM image
      run_command
      ;;
    ssh)
      # SSH to VM
      ssh_to_vm
      ;;
    shellcheck)       # action
      # Check script with shellcheck
      do_shellcheck="true"
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
  options="$1"
  case $options in
    debug)          # option
      # Enable debug mode
      do_debug="true"
      ;;
    dryrun)         # option
      # Enable dryrun mode (don't execute commands)
      do_dryrun="true"
      ;;
    dhcp)           # option
      # Use DHCP
      vm_dhcp="true"
      ;;
    force)          # option
      # Force action
      do_force="true"
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
      # Disable autostart
      do_autostart="false"
      ;;
    autostart)      # option
      # Enable autostart
      do_autostart="true"
      ;;
    nolocalds)      # option
      # Don't use cloud-localds
      do_localds="false"
      ;;
    localds)        # option
      # Use cloud-localds
      do_localds="true"
      ;;
    nolock*)        # option
      # Lock password
      do_lock="false"
      ;;
    lock*)          # option
      # Lock password
      do_lock="true"
      ;;
    nobacking)      # option
      # Don't use backing (creates a full copy of image)
      do_backing="false"
      ;;
    options|help)   # option
      # Print options help
      print_usage "options"
      exit
      ;;
    nomask)         # option
      # Disable masking of password and ssh keys
      do_mask="false"
      ;;
    mask)           # option
      # Enable masking of password and ssh keys
      do_mask="true"
      ;;
    noreboot)       # option
      # Disable reboot
      do_reboot="false"
      ;;
    reboot)         # option
      # Enable reboot
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
    --action*)             # switch
      # Action to perform (e.g. createvm,deletevm)
      check_value "$1" "$2"
      actions="$2"
      do_actions="true"
      shift 2
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
    --cdrom)              # switch
      # VM localds cdrom
      check_value "$1" "$2"
      vm_cdrom="$2"
      shift 2
      ;;
    --cidr)               # switch
      # VM CIDR
      check_value "$1" "$2"
      vm_cidr="$2"
      shift 2
      ;;
    --cloud*)              # switch
      # VM cloud-init config
      check_value "$1" "$2"
      vm_init_cfg="$2"
      shift 2
      ;;
    --cpus)               # switch
      # Number of VM CPUs
      check_value "$1" "$2"
      vm_cpus="$2"
      shift 2
      ;;
    --cputype)            # switch
      # Type of CPU within VM
      check_value "$1" "$2"
      vm_cputype="$2"
      shift 2
      ;;
    --crypt)              # switch
      # VM password crypt
      check_value "$1" "$2"
      vm_crypt="$2"
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
    --domain*)            # switch
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
    --features)           # switch
      # VM features
      check_value "$1" "$2"
      vm_features="$2"
      shift 2
      ;;
    --filegroup)          # switch
      # Set group of a file within VM image
      check_value "$1" "$2"
      vm_file_group="$2"
      shift 2
      ;;
    --fileowner)          # switch
      # Set owner of a file within VM image
      check_value "$1" "$2"
      vm_file_owner="$2"
      shift 2
      ;;
    --fileperms)          # switch
      # Set permissions of a file within VM image
      check_value "$1" "$2"
      vm_file_perms="$2"
      shift 2
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
      get_image
      shift
      exit
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
    --gecos)              # switch
      # GECOS field for user
      check_value "$1" "$2"
      vm_gecos="$2"
      shift 2
      ;;
    --groupid|--gid)      # switch
      # Group ID
      check_value "$1" "$2"
      vm_groupid="$2"
      shift 2
      ;;
    --group|--groupname)  # switch
      # Primary Group a user is member of in VM image
      check_value "$1" "$2"
      vm_groupname="$2"
      shift 2
      ;;
    --groups)             # switch
      # Additional groups a user is a member of in VM image
      check_value "$1" "$2"
      vm_groups="$2"
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
      vm_home_dir="$2"
      shift 2
      ;;
    --hostdevice)         # switch
      # VM host device pass-through
      check_value "$1" "$2"
      vm_host_device="$2"
      shift 2
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
    --mask)               # switch
      # Enable masking of password and ssh keys
      do_mask="true"
      shift
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
    --netc*|--networkc*)  # switch
      # VM network config file
      check_value "$1" "$2"
      vm_net_cfg="$2"
      shift 2
      ;;
    --netdev|--nic)       # switch
      # VM network device (e.g. enp1s0)
      check_value "$1" "$2"
      vm_net_dev="$2"
      shift 2
      ;;
    --option*)             # switch
      # Option(s) (e.g. verbose,dryrun)
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
    --power*)             # switch
      # VM power state
      check_value "$1" "$2"
      vm_power="$2"
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
    --shell)              # switch
      # User shell in VM image
      check_value "$1" "$2"
      vm_shell="$2"
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
    --source*|--input*)   # switch
      # Source file to copy into VM disk
      check_value "$1" "$2"
      source_file="$2"
      shift 2
      ;;
    --sshkey)             # switch
      # SSH key
      check_value "$1" "$2"
      ssh_key="$2"
      shift 2
      ;;
    --sshkeyfile)             # switch
      # SSH key file
      check_value "$1" "$2"
      ssh_key_file="$2"
      shift 2
      ;;
    --strict)             # switch
      # Run in strict mode
      do_strict="true"
      shift
      ;;
    --sudoers)            # switch
      # Sudoers entry
      check_value "$1" "$2"
      vm_sudoers="$2"
      shift 2
      ;;
    --userid|--uid)       # switch
      # User ID
      check_value "$1" "$2"
      vm_userid="$2"
      shift 2
      ;;
    --user|--username)    # switch
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
      # VM/libvirt base directory
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

# Reset default based on switches

reset_defaults

# Process options

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

# Process actions

if [ "$do_actions" = "true" ]; then
  if [[ "$actions" =~ "," ]]; then
    IFS="," read -r -a array <<< "$actions"
    for action in "${array[@]}"; do
      process_actions "$action"
    done
  else
    process_actions "$actions"
  fi
fi
