export def sleeping [] {
    bash -c "echo mem | sudo tee /sys/power/state > /dev/null"
}

