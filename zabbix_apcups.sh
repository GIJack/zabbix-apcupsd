#!/usr/bin/env sh

# NEEDS: apcaccess from apcupsd

# CONFIG - edit this for your system
APCACCESS=/usr/bin/apcaccess
ZABBIX_CONF=/etc/zabbix/zabbix_agentd.conf
ZABBIX_SENDER=/usr/bin/zabbix_sender
UPS_HOST=127.0.0.1
UPS_PORT=3551
#/CONFIG

zsend() {
  ${ZABBIX_SENDER} -c "${ZABBIX_CONF}" -k $1 -o "${2}"
}

datestamp() {
  # date with same format used by apcaccess
  local formatting="+%F %T %z"
  date "${formatting}"
}

check_files() {
  # check to ensure files in config exist, and that programs are executable
  failures=0

  # checking zabbix
  if [ ! -f "${ZABBIX_CONF}" ];then
    echo 1>&2 "ZABBIX_CONF Not found, check config at top of script"
    failures=$(( ${failures} + 1 ))
  fi
  if [ ! -x "${ZABBIX_SENDER}" ];then
    echo 1>&2 "ZABBIX_SENDER Not a program, check config at top of script. Looking for zabbix_sender in PATH"
    which zabbix_sender
    failures=$(( ${failures} + 1 ))
  fi

  # check apcaccess
  if [ ! -x ${APCACCESS} ];then
    echo 1>&2 "APACCESS not a program, check config at top of script. Looking for apcaccess in PATH"
    which apcaccess
    failures=$(( ${failures} + 1 ))
  fi
  
  if [ $failures -gt 0 ];then
    echo 1>&2 "Script config is not set up correctly. please check config at top of script. see errors above "
    exit 1
   else
    return 0
  fi
}

apcaccess_failed() {
  echo 1>&2  "apcaccess command failed. monitoring is broken, please check apcaccess and apcupsd to ensure it is setup and configured correctly. Also check config at top of this script."
  INFO="DATE	: $(datestamp)
apcaccess command failed. please ensure that apcupsd is running correctly, and
that the zabbix_apcups.sh script is setup correctly. Config is at the top.
try running apcaccess on the command line.
"
  zsend ups.is_online 0
  zsend ups.status "¡software_failed!"
  zsend ups.display_info "${INFO}"
  exit 1
}

main() {
  # check to make sure config is correct
  check_files
  
  # Get data from UPS
  DATA="$(${APCACCESS} -h ${UPS_HOST}:${UPS_PORT} )" || apcaccess_failed

  # Check online status. convert this to binary data
  status=$(echo "${DATA}" |grep -m1 STATUS | cut -d ":" -f 2)
  if [ ${status} == "ONLINE" ];then
    is_online=1
   else
    is_online=0
  fi
  
  if [ ${status} == "COMMLOST" ];then
  INFO="$(echo "${DATA}" |grep -m1 DATE )
Communication from host to APC UPS device has been lost. Please ensure cables
are connected and UPS remains operative and USB ports on host are operational.
"
  else
    INFO=$(cat << EOF
$(echo "${DATA}" |grep -m1 DATE )
$(echo "${DATA}" |grep -m1 VERSION )
$(echo "${DATA}" |grep -m1 DRIVER )
$(echo "${DATA}" |grep -m1 MODEL )
$(echo "${DATA}" |grep -m1 UPSNAME )
$(echo "${DATA}" |grep -m1 SERIALNO )
$(echo "${DATA}" |grep -m1 BATTDATE )
$(echo "${DATA}" |grep -m1 NOMPOWER )
$(echo "${DATA}" |grep -m1 FIRMWARE )
EOF
    )
  fi
  
  # update daemon
  BATTERY_PERCENT=$(echo "${DATA}" |grep -m1 BCHARGE | cut -d ":" -f 2| cut -d " " -f 2)
  zsend ups.batterypercent ${BATTERY_PERCENT}
  zsend ups.percentinvert $( echo 100 - ${BATTERY_PERCENT} | bc )
  zsend ups.timeleft $(echo "${DATA}" |grep -m1 TIMELEFT | cut -d ":" -f 2| cut -d " " -f 2)
  zsend ups.load $(echo "${DATA}" |grep -m1 LOADPCT | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.voltage $(echo "${DATA}" |grep -m1 LINEV | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.bvoltage $(echo "${DATA}" |grep -m1 BATTV | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.batterytimestamp $(echo "${DATA}" |grep -m1 BATTDATE | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.last_transfer $(echo "${DATA}" |grep -m1 LASTXFER | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.status ${status}
  zsend ups.is_online ${is_online}
  zsend ups.display_info "${INFO}"

}

main "${@}"
