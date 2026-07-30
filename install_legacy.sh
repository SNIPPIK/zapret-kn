#!/bin/sh

set -e

GITHUB="https://github.com/bol-van/zapret"
TMP="/tmp/zapret.tar.gz"

echo "========================================="
echo "      Zapret Automatic Installer"
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
curl -fsSL https://api.github.com/repos/bol-van/zapret/releases/latest \
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

rm -rf /opt/zapret

mkdir -p /opt

tar -xzf "$TMP" -C /opt

DIR=$(find /opt -maxdepth 1 -type d -name "zapret*" | head -n1)

if [ "$DIR" != "/opt/zapret" ]; then
    mv "$DIR" /opt/zapret
fi

#
# install_bin
#
echo
echo "[5/7] Установка бинарников..."

/opt/zapret/install_bin.sh

#
# Автозапуск
#
echo
echo "[6/7] Настройка..."

ln -sf /opt/zapret/init.d/sysv/zapret /opt/etc/init.d/S90Zapret

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

/opt/zapret/init.d/sysv/zapret restart-fw

exit 0
EOF

chmod +x /opt/etc/ndm/netfilter.d/000-zapret.sh

#
# Запуск
#
echo
echo "[7/7] Запуск..."

/opt/etc/init.d/S00fix start || true
/opt/etc/init.d/S90Zapret restart || /opt/etc/init.d/S90Zapret start || true

rm -f "$TMP"

echo
echo "========================================="
echo "✅ Zapret успешно установлен!"
echo "========================================="
echo
