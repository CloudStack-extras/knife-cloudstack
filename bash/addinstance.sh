#!/bin/bash

your_org="Your Organization Name Here"

which dialog >/dev/null 2>&1
if [ ! "$?" == "0" ]; then echo "This script needs the 'dialog' application. Please install this first. Eg: yum install dialog."; exit 1; fi


function display_gauge() {
(
  echo $1
  echo "###"
  echo "$1 %"
  echo "###"
) |
dialog --title "Retrieving Cloudstack information" --backtitle "${your_org}" --gauge "Please wait ...." 10 60 0
}


function choose_option() {
  MENU_OPTIONS=
  COUNT=0

  while IFS= read -r line
  do
    COUNT=$[COUNT+1]
    option=`echo $line | sed 's/\s/_/g'`
    MENU_OPTIONS="${MENU_OPTIONS}${COUNT} ${option} "
  done <<< "${!1}"

  cmd=(dialog --title "$2" --backtitle "${your_org}" --menu "$3" 0 0 0)
  options=(${MENU_OPTIONS})
  choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
  echo $choice
}

function get_option() {
  echo "${!1}" | sed -n "$2p" | sed -e 's/^ *//g' -e 's/ *$//g'
}

function get_input() {
  cmd=(dialog --title "$1" --backtitle "${your_org}" --inputbox "$2" 8 50)
  result=$("${cmd[@]}" 2>&1 >/dev/tty)
  echo $result
}

function confirm() {
  cmd=(dialog --title "$1"  --yesno "$2" 10 80)
  result=$("${cmd[@]}" 2>&1 >/dev/tty)
  echo $?
}

display_gauge 20
zone_tmp=$(knife cs zone list --noheader --fields "name" | grep -v '^#' )

# check zone here and exit if no zone info

display_gauge 40
service_tmp=$(knife cs service list --noheader --fields "name" | grep -v '^#' )

environment_tmp=$(knife environment list | grep -v '^#' | grep -v '_default')

os_tmp="windows
centos
ubuntu
gentoo"


cs_node_name=$(get_input "Cloudstack Node Name" "Enter your node name here")
if [ "${cs_node_name}" == "" ]; then clear; exit 1; fi

cs_os=$(choose_option "os_tmp" "Cloudstack OS" "Please choose your os")
if [ "${cs_os}" == "" ]; then clear; exit 1; fi
cs_os_name=$(get_option "os_tmp" $cs_os)

cs_zone=$(choose_option "zone_tmp" "Cloudstack Zones" "Please choose your zone")
echo "returns: $cs_zone"
if [ "${cs_zone}" == "" ]; then clear; exit 1; fi
cs_zone_name=$(get_option "zone_tmp" $cs_zone)

display_gauge 60
template_tmp=$(knife cs template list --noheader --fields "name" --filter "zonename:/${cs_zone_name}/i,ostypename:/${cs_os_name}/i" | grep -v '^#' )

display_gauge 80
network_tmp=$(knife cs network list --noheader --fields "name" --filter "zonename:/${cs_zone_name}/i" | grep -v '^#' )

cs_service=$(choose_option "service_tmp" "Cloudstack Services" "Please choose an service")
if [ "${cs_service}" == "" ]; then clear; exit 1; fi
cs_service_name=$(get_option "service_tmp" $cs_service)

cs_template=$(choose_option "template_tmp" "Cloudstack Templates" "Please choose an template")
if [ "${cs_template}" == "" ]; then clear; exit 1; fi
cs_template_name=$(get_option "template_tmp" $cs_template)

cs_network=$(choose_option "network_tmp" "Cloudstack Networks" "Please choose an network")
if [ "${cs_network}" == "" ]; then clear; exit 1; fi
cs_network_name=$(get_option "network_tmp" $cs_network)

for environment in $environment_tmp
do
  if [ "${cs_node_name:0:4}" == "$environment" ]
  then
    cs_environment_name=${cs_node_name:0:4}
  fi
done

if [ -z $cs_environment_name ]; then
  cs_environment=$(choose_option "environment_tmp" "Cloudstack Environment" "Please choose an environment")
  if [ "${cs_environment}" == "" ]; then clear; exit 1; fi
  cs_environment_name=$(get_option "environment_tmp" $cs_environment)
fi

cs_confirm=$(confirm "Is this information correct?" "Node name   : $cs_node_name \nZone        : $cs_zone_name \nService     : $cs_service_name \nTemplate    : $cs_template_name\nNetwork     : $cs_network_name\nEnvironment : $cs_environment_name")
if [ ! "${cs_confirm}" == "0" ]; then clear; exit 1; fi



##### Execute command ####

if [ "$cs_os_name" == "windows" ]
then
  echo Launching Windows instance and using WINRM to bootstrap.
  knife cs server create $cs_node_name --node-name "$cs_node_name" --template "$cs_template_name" --service "$cs_service_name" --zone "$cs_zone_name" --network "$cs_network_name" --bootstrap-protocol winrm --cloudstack-password --environment $cs_environment_name

else
  echo Launching Linux instance and using SSH to bootstrap.
  knife cs server create $cs_node_name --node-name "$cs_node_name" --template "$cs_template_name" --service "$cs_service_name" --zone "$cs_zone_name" --network "$cs_network_name"  --bootstrap-protocol ssh --cloudstack-password --environment "$cs_environment_name"
fi

