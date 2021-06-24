#!/usr/bin/env bash

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

apcaccess_failed() {
  echo 1>&2  "apcaccess command failed. monitoring is broken, please check apcaccess and apcupsd to ensure it is setup and configured correctly. Also check config at top of this script."
  DISPLAY_INFO="apcaccess command failed.
please ensure that apcupsd is running correctly, and that the zabbix_apcups.sh
script is setup correctly. Config is at the top.
"
  zsend ups.is_online 0
  zsend ups.status "¡software_failed!"
  zsend ups.display_info "${DISPLAY_INFO}"
  exit 1
}

main() {
  # Get data from UPS
  DATA="$(${APCACCESS} -h ${UPS_HOST}:${UPS_PORT} )" || apcaccess_failed

  # Check online status. convert this to binary data
  status=$(echo "${DATA}" |grep -m1 STATUS | cut -d ":" -f 2)
  if [ ${status} == "ONLINE" ];then
    is_online=1
   else
    is_online=0
  fi

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

  # update daemon
  zsend ups.batterypercent $(echo "${DATA}" |grep -m1 BCHARGE | cut -d ":" -f 2| cut -d " " -f 2)
  zsend ups.timeleft $(echo "${DATA}" |grep -m1 TIMELEFT | cut -d ":" -f 2| cut -d " " -f 2)
  zsend ups.load $(echo "${DATA}" |grep -m1 LOADPCT | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.voltage $(echo "${DATA}" |grep -m1 LINEV | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.bvoltage $(echo "${DATA}" |grep -m1 BATTV | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.batterytimestamp $(echo "${DATA}" |grep -m1 BATTDATE | cut -d ":" -f 2|cut -d " " -f 2)
  zsend ups.status ${status}
  zsend ups.is_online ${is_online}
  zsend ups.display_info "${INFO}"

}

main "${@}"
