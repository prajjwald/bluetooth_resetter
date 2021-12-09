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

cmd_restart() {

    SLEEP_INTERVAL=${1:-$DEFAULT_SLEEP_INTERVAL};

    cmd_stop
    cat << EOF
***********************************************************************************************************
    Sleeping for ${SLEEP_INTERVAL} seconds.  If you are unable to connect after bluetooth is started again:
        - try running with a bigger sleep interval, e.g.
            $(basename $0) restart 60 # 60 seconds
        - if this still doesn\'t work:
            - stop bluetooth first:
                $(basename $0) stop;
            - try restarting in a few minutes:
                $(basename $0) stop;
***********************************************************************************************************
EOF
    sleep ${SLEEP_INTERVAL};

    cmd_start
}

declare -F cmd_${1} > /dev/null || usage;
cmd_${1} ${2};
