# bypass-keenetic
- Обход блокировки в рашке
- Перезапуск `/opt/zapret/init.d/sysv/zapret restart`

Рабочие аргументы на текущий момент
```css
MODE_QUIC=0
NFQWS_OPT_DESYNC="--dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-ttl=0 --dpi-desync-repeats=7 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
NFQWS_OPT_DESYNC_QUIC="--dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-repeats=7 --dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin --new"
```

```css
Отличный конфиг, но он отвалил мне войс в дискорде. Я сделал вот так и получил все! Ютуб на всех девайсах дома, комп, телек, iphone, samsung и дискорд в браузере chrome с флагом --enable-quic --quic-version=h3-27 и в приложении на мобиле.

QUIC_PORTS=443,50000-65535
MODE_QUIC=1

NFQWS_OPT_DESYNC="--dpi-desync=fake,split2 --dpi-desync-ttl=7 --dpi-desync-ttl6=0 --dpi-desync-repeats=20 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"

NFQWS_OPT_DESYNC_QUIC="--dpi-desync=fake,split2 --dpi-desync-any-protocol --dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin --new --dpi-desync=fake --dpi-desync-repeats=15"
```

### Не забываем добавить в автозапуск
```
ln -s /opt/zapret/init.d/sysv/custom.d.exemples/50-discord /opt/etc/init.d/S50-discord
ln -s /opt/zapret/init.d/sysv/zapret /opt/etc/init.d/S90-zapret
```

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
