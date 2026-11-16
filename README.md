# Introduction

This is an slightly modified version of https://github.com/radxa/rockpi-penta to use average disk temperatures from SMART values instead of CPU temperature to control the fan speed of the Radxa Penta SATA HAT Top Board in combination with OMV and hd-idle (see https://github.com/adelolmo/hd-idle) to spin down inactive disk to save energy. 

The Radxa Penta SATA HAT Top Board with its fan is sitting directly on top of the disk, hence, it should cool the disks. The Raspberry Pi is far away from this fan. Consequently, it should be cooled with its own heat sink and fan.

Building the NAS was inspired by Jeff Geerling (see https://www.jeffgeerling.com/blog/2024/radxas-sata-hat-makes-compact-pi-5-nas), though I decided not to add four 8 TB Samsung EVO 870 QVO but used the pile of old laptop hard drives lying around here. However, HDDs get much hotter than SSDs, especially if they are stacked that tight.  

## Hardware

- Raspberry Pi 5 (sitting in (slightly modified) Argon NEO BRED for cooling purposes (without cover) and GPIO stacking header)
- Radxa Penta SATA HAT for Raspi 5 (see https://docs.radxa.com/en/accessories/penta-sata-hat)
- 4x 2.5" HDDs (or SSDs)
- Radxa Penta SATA HAT Top Board (see https://docs.radxa.com/en/accessories/penta-sata-hat/sata-hat-top-board)
- Noctua A4x20 5W PWM fan (the original fan was noisy and the revolutions per second could only be regulated moderately)
- Official Raspberry Pi 27W USB-C power supply 
- Box with various M2.5 hex brass spacers
- 3D printed cover (this is on my to do list; the Argon NEO BRED base offers some nice options to attache the cover)

## Software

- Openmediavault (see https://github.com/openmediavault/openmediavault and https://wiki.omv-extras.org/doku.php?id=omv7:armbian_bookworm_install)
- hd-idle (see https://github.com/adelolmo/hd-idle)
- Enable PCIe Gen 3 (see https://www.jeffgeerling.com/blog/2023/forcing-pci-express-gen-30-speeds-on-pi-5)
- This repo with its modified fan.py, misc.py, and additional shell script to read disk temperatures

## How does this work?

The HDDs should spin down after inactivity using hd-idle and its default idle time of 10 min. The fan should be controlled to cool the disks based on their temperatures read from SMART values. Although the hd-idle readme tells `Important note: hd-idle is not compatible with the usage of disk monitoring tools like smartmontools.` I found a way to make this fly:
- Modified fan.py to read average disk temperature from `/var/log/avg_disk_temps.log`. 
- Added a shells script (love it!) to write the average disk temperature to `/var/log/avg_disk_temps.log` using `-n standy` option of smartctl to not check temperatures from SMART values if disk are at standby, as reading of temperatures from SMART values would wake up disks. If at least one disk is active, the temperatures of all disks will be read from SMART values and the average temperature is written to the aforementioned file. When all the hard drives are at standby, the corresponding value for 25 °C is written once to the file, causing the fan to stop.
- Automate shell script (I picked 5 min) via OMV web GUI via "System" -> "Scheduled Tasks" -> `bash /usr/local/bin/log_avg_disk_temperature.sh`

Enjoy!

## GPIO chip renumbering fix

Newer Raspberry Pi OS kernels (6.6.45 and later) no longer expose the Pi 5's header GPIOs (RP1, `pinctrl-rp1`) as `/dev/gpiochip4`. Depending on kernel and device tree, the chip now shows up as `gpiochip0` or under a dynamically assigned number (e.g. `gpiochip15`). The original configuration hard-codes chip `4`, so after a kernel update the service crashes with `FileNotFoundError`. This results in the fan running at 100% and the OLED display stays dark.

Please note, that I fixed this in this fork only for the Raspberry Pi 5 and Raspberry Pi 4. The Rockchip boards should not be affected, as their GPIO chip numbers are derived in a different way.
- `env/rpi5.env` addresses the GPIO chip by its label (`pinctrl-rp1`) instead of a number, so it no longer matters which number the kernel assigns.
- `env/rpi4.env` also addresses the GPIO chip by its label (`pinctrl-bcm2711`). The Pi 4 is not affected by the renumbering today, but I wanted to make this a bit more robust for future changes. 
- `postinst` explicitly upgrades `adafruit-blinka` on installation, as older Blinka releases hard-code `gpiochip4` for the Pi 5 and break the OLED.

Please note, that I tested this on a Raspberry Pi 5. This was not tested on a Raspberry Pi 4.

## Note on OMV 8

This code uses the libgpiod v1 Python API. Debian Trixie, and so Raspberry Pi OS Trixie and OMV 8, ships python3-libgpiod v2 and that version removed this API. The Chip() only accepts a path, not a label. The service will crash there no matter what the .env files provide. On bookworm / OMV 7 you're fine. The update of this repo to make it fly with OMV 8 does sit on my todo list.

# Radxa Penta SATA

Official documentation:

[Penta SATA HAT documentation](https://docs.radxa.com/en/accessories/storage/penta-sata-hat)

[Penta SATA HAT Top Board documentation](https://docs.radxa.com/en/accessories/storage/penta-sata-hat/sata-hat-top-board)
