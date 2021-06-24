# zabbix-apcupsd
APC UPS monitoring using apcaccess for zabbix-agent

REQUIRES:
* apcupsd - make this this program is properly running, and configured. make
sure apcaccess gives proper results.

This script is designed to report local APC UPS usage to the zabbix agent,
using apcaccess and zabbix_sender.

USAGE:

On the Zabbix Server:
* import template_apcups.xml

On Client:
* install and configure zabbix agent
* edit zabbix_apcups.sh, change variables to suit your environment

```
mkdir -p /etc/zabbix/scripts

cp zabbix_postfix.sh /etc/zabbix/scripts/
chmod 750 /etc/zabbix/scripts/zabbix_apcups.sh
chgrp zabbix /etc/zabbix/scripts/zabbix_apcups.sh

```
* Add crontab entry
```
#APC UPS Check:
*/1 * * * * /etc/zabbix/scripts/zabbix_apcups.sh 1>/dev/null 2>/dev/null
```
**OR**

Use GNU Make

* make install	- installs files
* make remove	- removes installation


