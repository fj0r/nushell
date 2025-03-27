export def suspend [] {
    sudo bash -c 'echo "mem" > /sys/power/state'
}

