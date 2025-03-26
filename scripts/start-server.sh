#!/bin/bash
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/xdg
export XAUTHORITY=${DATA_DIR}/.Xauthority
export LANGUAGE="$LOCALE_USR"
export LANG="$LOCALE_USR"

echo "---Preparing Server---"
if [ ! -d ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/ ]; then
    mkdir -p ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/
fi
if [ ! -f ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ]; then
    cp /tmp/config/xfce4-desktop.xml ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/
fi
if [ ! -f ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ]; then
    cp /tmp/config/xsettings.xml ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/
fi
if [ ! -f ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml ]; then
    cp /tmp/config/xfce4-panel.xml ${DATA_DIR}/.config/xfce4/xfconf/xfce-perchannel-xml/
fi
if [ ! -d ${DATA_DIR}/.config/xfce4/panel ]; then
    cp -R /tmp/config/panel ${DATA_DIR}/.config/xfce4/
fi
if [ ! -d ${DATA_DIR}/.config/xfce4/terminal ]; then
    mkdir -p ${DATA_DIR}/.config/xfce4/terminal
fi
if [ ! -f ${DATA_DIR}/.config/xfce4/terminal/terminalrc ]; then
    cp /tmp/config/terminalrc ${DATA_DIR}/.config/xfce4/terminal/terminalrc
fi
if [ ! -d ${DATA_DIR}/.logs ]; then
    mkdir ${DATA_DIR}/.logs
fi
if [ ! -d ${DATA_DIR}/.local/share/applications ]; then
    mkdir -p ${DATA_DIR}/.local/share/applications
fi
if [ ! -d ${DATA_DIR}/.config/autostart ]; then
    mkdir -p ${DATA_DIR}/.config/autostart
fi
if [ ! -f ${DATA_DIR}/.config/autostart/light-locker.desktop ]; then
    echo "[Desktop Entry]
Hidden=true" > ${DATA_DIR}/.config/autostart/light-locker.desktop
fi

echo "---Checking for old logfiles---"
find ${DATA_DIR}/.logs -name "XvfbLog.*" -exec rm -f {} \;
find ${DATA_DIR}/.logs -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old lock files---"
rm -rf /tmp/.X99*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid 
chmod -R ${DATA_PERM} ${DATA_DIR}
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
    chmod 600 ${DATA_DIR}/.vnc/passwd
fi
screen -wipe 2&>/dev/null
find /var/run/dbus -name "pid" -exec rm -f {} \;

echo "---Starting dbus service---"
if dbus-daemon --config-file=/usr/share/dbus-1/system.conf ; then
    echo "---dbus service started---"
else
    echo "---Couldn't start dbus service---"
    sleep infinity
fi
sleep 2

echo "---Starting TurboVNC server---"
vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :99 -rfbport ${RFB_PORT} -noxstartup -noserverkeymap ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2

echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}
sleep 2

echo "---Starting CoolerControl AppImage---"
dbus-daemon --system --fork
sudo /opt/coolercontrol/CoolerControlD-x86_64.AppImage &
coolercontrol_pid=$!
sleep 5  # Allow time for initialization

echo "---Starting Desktop---"
if [ "${DEV}" == "true" ]; then
    xfce4-session
else
    xfce4-session 2> /dev/null
fi
