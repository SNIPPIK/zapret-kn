#!/bin/sh

set -e

GITHUB="https://github.com/bol-van/zapret2"
TMP="/tmp/zapret2.tar.gz"

echo "========================================="
echo "      Zapret2 Automatic Installer"
echo "========================================="
echo

#
# Проверка Entware
#
if [ ! -d /opt ]; then
    echo "❌ Entware не установлен."
    exit 1
fi

#
# Проверка opkg
#
if ! command -v opkg >/dev/null 2>&1; then
    echo "❌ opkg не найден."
    exit 1
fi

#
# Зависимости
#
echo "[1/7] Установка зависимостей..."

opkg update

opkg install \
    coreutils-sort \
    curl \
    grep \
    gzip \
    ipset \
    iptables \
    kmod_ndms \
    tar \
    xtables-addons_legacy

#
# Получение последнего релиза
#
echo
echo "[2/7] Получение последней версии..."

URL=$(
curl -fsSL https://api.github.com/repos/bol-van/zapret2/releases/latest \
| grep browser_download_url \
| grep tar.gz \
| head -n1 \
| cut -d '"' -f4
)

if [ -z "$URL" ]; then
    echo "Не удалось определить последнюю версию."
    exit 1
fi

echo "$URL"

#
# Скачивание
#
echo
echo "[3/7] Загрузка..."

curl -L "$URL" -o "$TMP"

#
# Удаляем старую установку
#
echo
echo "[4/7] Подготовка..."

rm -rf /opt/zapret2

mkdir -p /opt

tar -xzf "$TMP" -C /opt

DIR=$(find /opt -maxdepth 1 -type d -name "zapret2*" | head -n1)

if [ "$DIR" != "/opt/zapret2" ]; then
    mv "$DIR" /opt/zapret2
fi

#
# install_bin
#
echo
echo "[5/7] Установка бинарников..."

/opt/zapret2/install_bin.sh

#
# Автозапуск
#
echo
echo "[6/7] Настройка..."

ln -sf /opt/zapret2/init.d/sysv/zapret2 /opt/etc/init.d/S90Zapret2

cat >/opt/etc/init.d/S00fix <<'EOF'
#!/bin/sh

start() {
    sysctl -w net.netfilter.nf_conntrack_checksum=0 >/dev/null 2>&1
}

stop() {
    sysctl -w net.netfilter.nf_conntrack_checksum=1 >/dev/null 2>&1
}

case "$1" in
    start) start ;;
    stop) stop ;;
    *) stop; start ;;
esac

exit 0
EOF

chmod +x /opt/etc/init.d/S00fix

mkdir -p /opt/etc/ndm/netfilter.d

cat >/opt/etc/ndm/netfilter.d/000-zapret.sh <<'EOF'
#!/bin/sh

[ "$table" != "mangle" ] && [ "$table" != "nat" ] && exit 0

/opt/zapret2/init.d/sysv/zapret2 restart-fw

exit 0
EOF

chmod +x /opt/etc/ndm/netfilter.d/000-zapret.sh

#
# Запуск
#
echo
echo "[7/7] Запуск..."

/opt/etc/init.d/S00fix start || true
/opt/etc/init.d/S90Zapret2 restart || /opt/etc/init.d/S90Zapret2 start || true

rm -f "$TMP"

echo
echo "========================================="
echo "✅ Zapret2 успешно установлен!"
echo "========================================="
echo
