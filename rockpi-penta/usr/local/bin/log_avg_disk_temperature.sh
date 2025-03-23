#!/bin/bash
LOG_FILE="/var/log/avg_disk_temps.log"
total_temp=0
count=0
active_disks=0  # Track if any disk is active

while read -r disk; do
    # Check if the disk is active (not in standby)
    if smartctl -n standby -A "$disk" &>/dev/null; then
        active_disks=$((active_disks + 1))  # At least one active disk
        temp=$(smartctl -A "$disk" | awk '/Temperature_Celsius/ {print $10}')
        if [[ -n "$temp" ]]; then
            total_temp=$(echo "$total_temp + $temp" | bc)  # Accumulate temperatures
            count=$((count + 1))
        fi
    fi
done < <(smartctl --scan | awk '{print $1}')

if [[ $count -gt 0 ]]; then
    avg_temp=$(echo "scale=5; $total_temp / $count * 1000" | bc)  # Multiply by 1000
    avg_temp=$(printf "%.0f" "$avg_temp")  # Remove decimals
    echo "$avg_temp" > "$LOG_FILE"
elif [[ $active_disks -eq 0 ]]; then
    echo "25000" > "$LOG_FILE"  # All disks are in standby, assuming that they are at 25 °C
fi
