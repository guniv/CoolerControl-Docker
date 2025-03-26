#!/bin/bash
echo "---Ensuring UID: ${UID} matches user---"
usermod -u ${UID} ${USER}
echo "---Ensuring GID: ${GID} matches user---"
groupmod -g ${GID} ${USER} > /dev/null 2>&1 ||:
usermod -g ${GID} ${USER}
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "root:${ROOT_PWD}" | chpasswd
export ROOT_PWD="secret"

echo "---Checking for optional scripts---"
cp -f /opt/custom/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:
cp -f /opt/scripts/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:

if [ -f /opt/scripts/start-user.sh ]; then
    echo "---Found optional script, executing---"
    chmod -f +x /opt/scripts/start-user.sh ||:
    /opt/scripts/start-user.sh || echo "---Optional Script has thrown an Error---"
else
    echo "---No optional script found, continuing---"
fi

if [ ! -d /tmp/xdg ]; then
	mkdir /tmp/xdg
fi

sed -i "/  <user>/c\  <user>${USER}</user>" /usr/share/dbus-1/system.conf

echo "---Configuring Locales to: ${USER_LOCALES}---"
LOCALE_GEN=$(head -n 1 /etc/locale.gen)
export LOCALE_USR="${USER_LOCALES%% *}"

if [ "$LOCALE_GEN" != "${USER_LOCALES}" ]; then
	rm /etc/locale.gen
	echo -e "${USER_LOCALES}\nen_US.UTF-8 UTF-8" > "/etc/locale.gen"
	export LANGUAGE="$LOCALE_USR"
	export LANG="$LOCALE_USR"
	export LC_ALL="$LOCALE_USR" 2> /dev/null
	sleep 2
	locale-gen
	update-locale LC_ALL="$LOCALE_USR"
else
	echo "---Locales set correctly, continuing---"
fi

echo "---Checking configuration for noVNC---"
novnccheck

echo "---Taking ownership of data...---"
rm -R ${DATA_DIR}/.dbus/session-bus/* 2> /dev/null
if [ ! -d /var/run/dbus ]; then
	mkdir -p /var/run/dbus
fi
chown -R ${UID}:${GID} /var/run/dbus/
chmod -R 770 /var/run/dbus/
chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} /tmp/xdg
chmod -R 0700 /tmp/xdg
dbus-uuidgen > /var/lib/dbus/machine-id
rm -R /tmp/.* 2> /dev/null
mkdir -p /tmp/.ICE-unix
chown root:root /tmp/.ICE-unix/
chmod 1777 /tmp/.ICE-unix/
chown -R ${UID}:${GID} ${DATA_DIR}
chown -R ${UID}:${GID} /tmp/config
chown -R ${UID}:${GID} /mnt/

echo "---Starting XFCE and NoVNC---"
term_handler() {
	echo "---Stopping CoolerControl---"
	[ -n "$coolercontrol_pid" ] && kill -SIGTERM "$coolercontrol_pid"
	wait "$coolercontrol_pid" 2>/dev/null

	export DISPLAY=:99 && su ${USER} -c "xfce4-session-logout --halt"
	tail --pid="$(pidof xfce4-session)" -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM
su ${USER} -c "/opt/scripts/start-server.sh" &
killpid="$!"
while true
do
	wait $killpid
	exit 0;
done
