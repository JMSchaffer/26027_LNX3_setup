#!/bin/bash

#UDEV_INSTALL_FILNAME="$HOME/z999-mchp_debugger_test.rules"
UDEV_INSTALL_FILNAME="/etc/udev/rules.d/z999-mchp_debugger.rules"

# Check to see if the rule is installed and, if not, install it

#if [ ! -f /etc/udev/rules.d/z999-mchp_debugger.rules ]; then
if [ ! -f "$UDEV_INSTALL_FILNAME" ]; then
    echo ""
    echo ""
    echo "*******************************************************************************"
    echo "********************* Installing MCHP Debugger udev rule **********************"
    echo "*******************************************************************************"
    echo ""
    echo ""

	sudo tee "$UDEV_INSTALL_FILNAME" <<'EOF' > /dev/null
# Bind ftdi_sio driver to all input
ACTION=="add", ATTRS{idVendor}=="1514", ATTRS{idProduct}=="200a", \
ATTRS{product}=="MCHP-Debug", ATTR{bInterfaceNumber}!="00", \
RUN+="/sbin/modprobe ftdi_sio", RUN+="/bin/sh -c 'echo 1514 200a > /sys/bus/usb-serial/drivers/ftdi_sio/new_id'"

# Unbind ftdi_sio driver for channel A which should be the JTAG
SUBSYSTEM=="usb", DRIVER=="ftdi_sio", ATTR{bInterfaceNumber}=="00", \
RUN+="/bin/sh -c 'echo $kernel > /sys/bus/usb/drivers/ftdi_sio/unbind'"
# Helper (optional)
KERNEL=="ttyUSB[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", \
ATTRS{interface}=="MCHP-Debug", ATTRS{bInterfaceNumber}=="01", \
SYMLINK+="ttyUSB-MCHPDebugSerialB" GROUP="dialout" MODE="0666"
KERNEL=="ttyUSB[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", \
ATTRS{interface}=="MCHP-Debug", ATTRS{bInterfaceNumber}=="02", \
SYMLINK+="ttyUSB-MCHPDebugSerialC" GROUP="dialout" MODE="0666"
KERNEL=="ttyUSB[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", \
ATTRS{interface}=="MCHP-Debug", ATTRS{bInterfaceNumber}=="03", \
SYMLINK+="ttyUSB-MCHPDebugSerialD" GROUP="dialout" MODE="0666"
EOF

    echo ""
    echo ""
    echo "********************************************************"
    echo "********************* Rules Added **********************"
    echo "********************************************************"
    echo ""
    echo ""

else
    echo ""
    echo ""
    echo "********************************************************"
    echo "************* Rules File already exists!! **************"
    echo "********************************************************"
    echo ""
    echo ""


fi