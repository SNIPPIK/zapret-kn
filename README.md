# bypass-keenetic
- Обход блокировки (youtube, discord)
- Перезапуск `/opt/zapret/init.d/sysv/zapret restart`
- Для начала работы надо установить zapret на keenetic
- Все готово и настроено бери и пользуйся
- Необходим OPKG!

### Не забываем добавить в автозапуск
```
ln -s /opt/zapret/init.d/sysv/custom.d.exemples/50-discord /opt/etc/init.d/S50-discord
ln -s /opt/zapret/init.d/sysv/zapret /opt/etc/init.d/S90-zapret
```

### Для Discord voice
- Уже включен в `zapret 68.zip`
- Добавьте в init.d/sysv/functions:
```
# Fix local source ip issue when quic packets were sent with raw sockets (no Keenetic-specific iptable marks were applied)
fw_nfqws_quic_masquarade()
{
    # $1 - 1 - add, 0 - del
    # $2 - iptable filter
    local rule
    ipt_print_op $1 "$2" "nfqws quic masquerade"
    rule="$2 -d 0/0 -j MASQUERADE"
    if [ -n "$IFACE_WAN" ] ; then
	for wan in $IFACE_WAN; do
		ipt_add_del $1 POSTROUTING -t nat -o $wan $rule
	done
    else
	ipt_add_del $1 POSTROUTING -t nat $rule
    fi
}
```

- В custom скрипте init.d/sysv/custom.d/50-discord:
```
zapret_custom_firewall()
{
    # ...
    fw_nfqws_quic_masquarade $1 "-p udp -m multiport --dports $DISCORD_PORTS_IPT -m mark --mark $DESYNC_MARK/$DESYNC_MARK"
    #...
```
