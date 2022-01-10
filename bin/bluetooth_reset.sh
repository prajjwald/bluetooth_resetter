#!/bin/bash

# You can change the sleep time between stop and start by passing it as a parameter to the script
# See Usage
DEFAULT_SLEEP_INTERVAL=3;

#BLUETOOTH_MODS="btusb btrtl btintel btbcm bnep btusb rfcomm";
BLUETOOTH_MODS="btusb btrtl btintel btbcm btusb rfcomm";

usage() {
    echo "Usage: $(basename $0) [start|stop|restart <restart_interval=3>|info]";
    exit;
}

forMods() {
    CMD=$1;
    for mod in ${BLUETOOTH_MODS};
    do
        echo $mod;
        sudo ${CMD} $mod;
    done
}

cmd_info() {
    BLUETOOTH_ID=$(rfkill list | grep hci | cut -d: -f1);
    echo "bluetooth id is ${BLUETOOTH_ID}"
    lsmod|grep bluetooth;
    rfkill list ${BLUETOOTH_ID};
}

cmd_start() {
    echo "Attempting to probe modules"
    forMods modprobe;

    #Bluetooth id changes after rmmod/modprobe
    BLUETOOTH_ID=$(rfkill list | grep hci | cut -d: -f1);
    echo "Starting up Bluetooth: id is ${BLUETOOTH_ID}";
    sudo rfkill unblock ${BLUETOOTH_ID};
    cmd_info;
}

cmd_stop() {
    BLUETOOTH_ID=$(rfkill list | grep hci | cut -d: -f1);
    echo "Shutting down Bluetooth: id is ${BLUETOOTH_ID}";
    sudo rfkill block ${BLUETOOTH_ID};

    echo "Attempting to remove modules"
    forMods rmmod;
}

disconnnect_devices_and_note_active() {
    echo "Disconnecting any connected devices..."
    # Nothing to do if bluetoothctl is not installed
    type -t bluetoothctl > /dev/null || return;
    ALLDEVICES=$(bluetoothctl devices | awk '/Device/ {print $2}');
    CONNECTED=""
    for device in ${ALLDEVICES};
    do
        # If currently connected - add device to list of previously connected devices
        bluetoothctl info ${device} | grep "Connected: yes" > /dev/null 2>&1 && CONNECTED="${CONNECTED} ${device}";
        # disconnect device regardless of connection status
        # this seems to help sometimes if there was an ongoing connection attempt during reset
        bluetoothctl disconnect ${device} > /dev/null 2>&1;
    done
}

reconnect_previously_active_devices() {
    # Nothing to do if bluetoothctl is not installed
    type -t bluetoothctl > /dev/null || return;

    echo "Reconnecting previously connected devices";

    # CONNECTED is a global variable - this was set in the disconnect function
    # more convenient than explicit passing in this case
    for device in ${CONNECTED};
    do
        bluetoothctl info ${device}|head -2;
        bluetoothctl connect ${device};
    done
}

cmd_restart() {

    SLEEP_INTERVAL=${1:-$DEFAULT_SLEEP_INTERVAL};
    # Interval to wait before attempting reconnect of previously active devices
    RECONNECT_INTERVAL=10;
    WAIT_BEFORE_EXIT_SCRIPT_INTERVAL=${2:-0};

    disconnnect_devices_and_note_active
    cmd_stop
    cat << EOF
***********************************************************************************************************
    Sleeping for ${SLEEP_INTERVAL} seconds.  If you are unable to connect after bluetooth is started again:
        - try running with a bigger sleep interval, e.g.
            $(basename $0) restart 60 # 60 seconds
        - if this still doesn't work:
            - stop bluetooth first:
                $(basename $0) stop;
            - try restarting in a few minutes:
                $(basename $0) stop;
***********************************************************************************************************
EOF
    sleep ${SLEEP_INTERVAL};

    cmd_start

    [ -z "${CONNECTED}" ] || {
        echo "sleeping ${RECONNECT_INTERVAL} before reconnecting devices";
        sleep ${RECONNECT_INTERVAL};
        reconnect_previously_active_devices
    }

    # Sleep some more before returning for desktop launch so user can see output if they want
    [ ${WAIT_BEFORE_EXIT_SCRIPT_INTERVAL} -gt 0 ] && {

        echo "Sleeping for ${WAIT_BEFORE_EXIT_SCRIPT_INTERVAL} seconds before exiting script";
        sleep ${WAIT_BEFORE_EXIT_SCRIPT_INTERVAL};

    }
}

declare -F cmd_${1} > /dev/null || usage;
cmd_${1} ${2} ${3};
