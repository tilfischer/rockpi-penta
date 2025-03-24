# Introduction

This is an slightly modified version of https://github.com/radxa/rockpi-penta to use average disk temperatures from SMART values instead of CPU temperature to control the fan speed of the Radxa Penta SATA HAT Top Board in combination with OMV and hd-idle (see https://github.com/adelolmo/hd-idle) to spin down inactive disk to save energy. 

The Radxa Penta SATA HAT Top Board with its fan is sitting directly on top of the disk, hence, it should cool the disks. The Raspberry Pi is far away from this fan and is cooled with its own heat sink and fan.

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

--- CONTENT OF ORIGINAL README ---

# ROCK Pi Penta SATA

Top Board control program

[Penta SATA HAT wiki](<https://wiki.radxa.com/Penta_SATA_HAT>)

[Penta SATA HAT docs](https://docs.radxa.com/en/accessories/penta-sata-hat)

![penta-hat](images/penta-sata-hat.png)
