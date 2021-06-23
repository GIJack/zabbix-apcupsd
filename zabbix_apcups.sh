#!/usr/bin/env bash

# NEEDS: apcaccess from apcupsd

# CONFIG - edit this for your system
APCACCESS=/usr/bin/apcaccess
ZABBIX_CONF=/etc/zabbix/zabbix_agentd.conf
ZABBIX_SENDER=/usr/bin/zabbix_sender
UPS_HOST=127.0.0.1
UPS_PORT=3551
#/CONFIG

function zsend {
   ${ZABBIX_SENDER} -c $ZABBIX_CONF -k $1 -o $2
}

# Get data from UPS
DATA="$(${APCACCESS} -h ${UPS_HOST}:${UPS_PORT} )"

# Check online status. convert this to binary data
status=$(echo "${DATA}" |grep -m1 STATUS | cut -d ":" -f 2)
if [ ${status} == "ONLINE" ];then
  status=1
 else
  status=0
fi

zsend ups.batterypercent $(echo "${DATA}" |grep -m1 BCHARGE | cut -d ":" -f 2)
zsend ups.timeleft $(echo "${DATA}" |grep -m1 TIMELEFT | cut -d ":" -f 2)
zsend ups.load $(echo "${DATA}" |grep -m1 LOADPCT | cut -d ":" -f 2)
zsend ups.voltage $(echo "${DATA}" |grep -m1 LINEV | cut -d ":" -f 2)
zsend ups.status $(echo ${status} )
