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

# Get data from UPS
DATA="$(${APCACCESS} -h ${UPS_HOST}:${UPS_PORT} )"

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
zsend ups.status ${status}
zsend ups.is_online ${is_online}
zsend ups.display_info "${INFO}"
