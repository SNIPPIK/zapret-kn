# bypass-keenetic
- Обход блокировки в рашке
- Перезапуск `/opt/zapret/init.d/sysv/zapret restart`


Рабочие аргументы на текущий момент
```css
MODE_QUIC=0
NFQWS_OPT_DESYNC="--dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-ttl=0 --dpi-desync-repeats=7 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
NFQWS_OPT_DESYNC_QUIC="--dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-repeats=7 --dpi-desync-fake-quic=/opt/zapret/files/fake/quic_initial_www_google_com.bin --new"
```


### ИНСТРУКЦИЯ НЕ ПОД "СКОПИРОВАЛ ВСТАВИЛ", НАДО ХОТЬ ЧУТЬ ВНИКАТЬ !!!
У меня keenetic extra 2. У него автоматом не грузились некоторые модули ядра.

insmod /lib/modules/4.9-ndm-4/xt_multiport.ko
insmod /lib/modules/4.9-ndm-4/xt_connbytes.ko
insmod /lib/modules/4.9-ndm-4/xt_NFQUEUE.ko

Вместо 4.9-ndm-4, у вас скорее всего будет другая версия вашего ядра.

Посмотреть загруженные модули
lsmod

Посмотреть все модули которые есть
ls /lib/modules/4.9-ndm-4

После проделанного, iptables: No chain/target/match by that name., должно починиться.

В /opt/zapret/config у меня стоит

WS_USER=nobody
MODE_FILTER=none

# ВНИМАНИЕ!!! Используется косая кавычка для объединения строк для красоты.
# WORD="ба"`      `"нан" в переменной WORD будет "банан", при переносе косой кавычки на след. строку результат будет аналогичен.
NFQWS_OPT_DESYNC=""`

`" --hostlist=/opt/zapret/ipset/youtube.txt"`
`" --dpi-desync=fake,disorder --dpi-desync-split-pos=50 --dpi-desync-ttl=3 --dpi-desync-fooling=md5sig"`
`" --dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin --dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sni"`
`" --dpi-desync-repeats=20"`


`" --new --hostlist=/opt/zapret/ipset/my-list.txt"`
`" --dpi-desync=fake,disorder2 --dpi-desync-autottl --dpi-desync-fooling=datanoack,md5sig"


MODE_QUIC=1
NFQWS_OPT_DESYNC_QUIC="--dpi-desync=fake --dpi-desync-repeats=7"

Единственное, что может всё сломать это --dpi-desync-ttl=, подбирается индивидуально.

вы - - - dpi - - X - - - сервер где лежит ваш ресурс
Упрощено, ваша задача, раааазными схемами, подобрать время жизни пакета (ttl), чтобы он умирал после коробки dpi, но не успел еще дойти до сервера вашего сайта куда вы подключаетесь.
т.е в диаграмме с черточками вам будет достаточно ttl 7, чтобы пакет умер в X.
(считаем все черточки (узлы в реальности) и слово dpi (тоже узел) )
(tracert smth.com покажет все узлы которые вы проходите до сервера)

Чтобы это сделать для конкретного сайта (допустим googlevideo.com) берёте ping -i тут_цифра googlevideo.com -i ограничивает время жизни (ttl), пишите подбираете цифру чтобы пинг не доходил (будет писать Превышен срок жизни (TTL) при передаче пакета.).
возьмёте слишком маленький "ttl", то умрёте не дойдя до коробки dpi, пример Y
вы - Y - dpi - - X - - - сервер где лежит ваш ресурс

Это не подробный гайд, а просто наводка в какую сторону копать, есть нюансы, что на пути будет много коробок dpi и там будет нужно учесть (брать больший ttl), есть auto ttl читайте мануал запрета (если кто-то задается вопросом: "зачем мы пытаемся убить пакет (читайте мануал запрета), кратко, подобранный ttl будет применяться только к пакетам для обмана(что за пакеты читайте в описании disorder в мануале запрета) они не корректные поэтому и ломают коробку dpi, если мы допустим их до сервера ресурса до которого вы стучите то считайте, что сломаете и его").

Пояснение

У меня три стратегии

    Первая применяется к хостам из /opt/zapret/ipset/youtube.txt (там только googlevideo.com)
    Вторая применяется к хостам из /opt/zapret/ipset/my-list.txt (там все остальное, что подверглось блокировке, за основу взят
    https://antizapret.prostovpn.org/domains-export.txt + дискорд домены + ютуб домены (ищите в соответствующих соседних тредах)
    Третья для работы QUIC, я использую без хостлиста

Внимание!!!
Для работы дурения на уровне UDP (quic, discord voice, ...) на кинетиках требуется правило в ipset
добавить можно так iptables -t nat -A POSTROUTING -o eth2.2 -j MASQUERADE, вместо eth2.2 пишите то, что у вас в конфиге запрета $IFACE_WAN, при перезагрузке слетает, так же может слетать рандомно из-за особенностей кинетика (но это не точно). (Подробнее как правильно прописать ищите в доп. ссылках, ориентируйтесь на ipset правило, которое написано выше).

Обход для discord у меня работает, но написан по своему (в этом коменте он не описан), распространенный рабочий вариант ищите в соседних тредах #475.

Доп. ссылки
https://habr.com/ru/articles/834826/ (там можно найти патчи насчет доп. правила для quic)
https://telegra.ph/Nastrojka-zapret-ot-bol-van-na-Keentic-04-27 (там можно найти патчи чтобы не слетало правило)
#475 (comment)

Провайдер Wifire (Netbynet) дочка зеленого оператора МСК.
