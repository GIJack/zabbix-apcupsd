ZABBIX_BASE="etc/zabbix/"
install:
	install -Dm 750 zabbix_apcups.sh "$(DESTDIR)/$(ZABBIX_BASE)/scripts/zabbix_apcups.sh"
	chgrp zabbix "$(DESTDIR)/$(ZABBIX_BASE)/scripts/zabbix_apcups.sh"
	install -Dm 644 zabbix-apcups.cron "$(DESTDIR)/etc/cron.d/zabbix-apcups"
remove:
	rm "$(DESTDIR)/$(ZABBIX_BASE)/scripts/zabbix_apcups.sh"
	rm "$(DESTDIR)/etc/cron.d/zabbix-apcups"
