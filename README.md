# greenctld
Greenctld is a driver that enables hamlib and SatNOGS to communicate with the Green Heron Engineering RT-21 Rotator Controller. The GAS Team has made several modifications to the [original repository](https://github.com/mct/greenctld). For use with the GASGroundStation code, Raspberry Pi 4, and Alfa Spid RAS Az/El rotator, the installation instructions below must be followed. All changes made by [cartertpage](https://github.com/cartertpage) and [jackadanos](https://github.com/jackadanos).
## Table of Contents
* [GAS Team Changes](#gas-team-changes)
* [Installation Instructions](#installation-instructions)
* [Configuring udev Rules](#configuring-udev-rules)
* [Rotator Controller Settings](#rotator-controller-settings)
* [Adding make-run.sh to the Crontab](#adding-make-runsh-to-the-crontab)
* [Manually Commanding the Rotator](#manually-commanding-the-rotator)
* [Rotator Controller Settings](#rotator-controller-settings)
* [Original README](#original-readme)
  * [Usage](#usage)
  * [License](#license)


## GAS Team Changes

* ```make-run.sh```, cron job bash script that ensures ```greenctld``` is always running

* ```gasctld-log.txt```, status output from ```make-run.sh```

* ```requirements.txt```, for easy installation of the dependency Python 2.7 package ```pySerial```


## Installation Instructions

1. Clone the repository:
   ```python
   git clone https://github.com/SmallSatGasTeam/greenctld.git
   ```
2. Rename the "greenctld" directory to "gasctld":
   ```python
   mv greenctld/ gasctld/
   ```
3. Install Python 2.7:
   ```python
   sudo apt install python2
   ```
4. Install pip2:
   ```python
   curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
   ```
   ```python
   python2 get-pip.py
   ```
5. Install dependencies:
   ```python
   pip2 install -r requirements.txt
   ```


## Configuring udev Rules
The rotator controller connects to the Raspberry Pi using two separate USB cords. When the Pi boots up, it assigns the two cords specific device paths (/dev/). If we do not create udev rules, the device paths could change randomly. Creating the udev rules will ensure the azimuth cord is always on `/dev/azimuth` and the elevation cord is always on `/dev/elevation`.

#### 1. Determine which cord is which:
1. On the rotator controller, turn the knobs to set the azimuth to 180 and the elevation to 0.
2. The two cords will usually be `/dev/ttyUSB0` and `/dev/ttyUSB1` (or `/dev/ttyACM0` and `/dev/ttyACM1`. If so, adjust the following accordingly).
3. Run through [Manually Commanding the Rotator](#manually-commanding-the-rotator) using `./greenctld --az-device /dev/ttyUSB0 --el-device /dev/ttyUSB1` for step 1.
4. Run the "Get Position" command. If your output is:
    * `P 180 0`, we guessed the device paths correctly, therefore azimuth = `/dev/ttyUSB0` and elevation = `/dev/ttyUSB1`.

    * `P 0 180`, we guessed the device paths incorrectly, therefore elevation = `/dev/ttyUSB0` and azimuth = `/dev/ttyUSB1`.

#### 2. Get specific cords' serial values:
In order to write the udev rules, we must determine each cord's serial values, which are one of the only unique identifiers between the two. 
1. For this, we will assume that azimuth = `/dev/ttyUSB0` and elevation = `/dev/ttyUSB1`. If yours are the other way around, adjust the following accordingly.
2. Run the following commands to determine the serial values for each cord. The first is for `/dev/ttyUSB0` and the second is for `/dev/ttyUSB1`. The output of each should look like `ATTRS{serial}=="AB0N4HB4"`, along with some other rows. Be sure to write down the value "AB0N4HB4" and note for which cord it is for, as we will be using that number in the next section.
    ```
    udevadm info -a -n /dev/ttyUSB0 | grep serial
    ```
    ```
    udevadm info -a -n /dev/ttyUSB1 | grep serial
    ```

#### 3. Create the udev rules:
1. Open a new file in the udev directory.
    ```
    sudo nano /etc/udev/rules.d/99-usb-serial.rules
    ```
2. Copy and paste the following lines, replacing `XXXXXXXX` with the appropriate serial values we determined in the previous section.
    ```
    SUBSYSTEM=="tty", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{serial}=="XXXXXXXX", SYMLINK+="azimuth"
    SUBSYSTEM=="tty", SUBSYSTEMS=="usb", DRIVERS=="usb", ATTRS{serial}=="XXXXXXXX", SYMLINK+="elevation"
    ```
3. Exit and save the document.

#### 4. Test the new udev rules:
1. Reload the udev rules.
    ```
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    ```
2. List our new udev rules. If they are not found, then you have a problem! If they are listed, you did it! The two USB cords should now reliably connect to `/dev/azimuth` and `/dev/elevation`.
    ```
    ls /dev/azimuth /dev/elevation
    ```


## Rotator Controller Settings
The settings the GAS Team uses for the RT-21 controller with the Alfa Spid RAS rotator are as follows:
```
Calibration = 180 (displayed number should be aligned with actual direction of antenna)
Offset = 0
Delays = 0
Min Speed = 3
Max Speed = 10
CCW Limit = 181
CW Limit = 179
Option = SPID
Divide Hi = 360
Divide Lo = 360
Knob Time = 40
Mode = NORMAL
Ramp = 3
Bright = 1
```


## Adding make-run.sh to the Crontab
1. Open the crontab:
    ```
    crontab -e
    ```
2. Copy and paste the following two lines. The first will run `greenctld` at reboot, and the second will run `make-run.sh` every five minutes.
    ```
    @reboot ./gasctld/greenctld --az-device /dev/azimuth --el-device /dev/elevation
    ```
    ```
    */5 * * * * ./gasctld/make-run.sh
    ```
3. To ensure `greenctld` is running, you should be able to run `htop` and see the process `/usr/bin/python2 ./gasctld/greenctld --az-device /dev/azimuth --el-device /dev/elevation` running.


## Manually Commanding the Rotator
The following can be used to manually command the rotator from a command line. You should only expect to use this in testing/troubleshooting.

1. If ```greenctld``` is not running, run the script:
   ```python
   ./greenctld --az-device <az serial port> --el-device <el serial port>
   ```
   If you do not yet know `<az serial port>` and `<el serial port>`, you should probably run through (Configuring udev Rules)[#configuring-udev-rules] first.
   
2. From a separate terminal, connect to the rotator controller's port:
   ```python
   nc localhost 4533
   ```
3. The following commands can now be run:
   * Get position: `p` (lowercase p)
   * Set position: `P <Az> <El>` (uppercase P)
     * Example: `P 150 20` sets the Azimuth to 150 deg and the Elevation to 20 deg.
   * Halt movement: `S` (uppercase S)


## Original README

A hamlib-compatible driver for the [Green Heron Engineering RT-21 Digital Rotor
Controller](https://www.greenheronengineering.com/prod_documents/controllers/docs/RT-21_Manual_current.pdf).
hamlib does not support the rotor, but this program can be used as a drop-in
replacement for rotctld when commanding the RT-21.

The RT-21 is unlike most of the other rotors hamlib supports in that it uses
two serial ports, one for controlling azimuth and one for controlling
elevation.  The two serial ports are passed via the ```--az-device``` and
```--el-device``` command line arguments.

The TCP network protocol is compatible with the hamlib protocol documented in
the [rotctld(8) man
page](http://manpages.ubuntu.com/manpages/zesty/man8/rotctld.8.html).  This
driver only implements a subset of that protocol, which includes the subset
that [gpredict](http://gpredict.oz9aec.net/) uses.  At [Astro
Digital](https://astrodigital.com/), this driver has been used extensively with
gpredict.  For debugging the network protocol, the ```--dummy``` option can be
used to simulate a rotor without connecting to a real serial port.

Like rotctld, this program does not daemonize on its own.  It also produces
copious debugging output to stdout.


### Usage

 * ```--az-device <serial-port>```, the serial port to use for azimuth

 * ```--el-device <serial-port>```, the serial port to use for elevation

 * ```--speed <baud>```, the serial baud rate to use, defaults to 4800

 * ```--timeout <seconds>```, the serial port timeout, defaults to 1.5

 * ```--port <port>```, the TCP port to listen for connections on, defaults to 4533, the same as rotctld

 * ```--get-pos```, to query the serial ports for the current az/el, and immediately exit.  Useful for testing the serial port configuration.

 * ```--dummy```, to speak the TCP network protocol only without connecting to a serial port, useful for debugging gpredict integration.


### License

Copyright (c) 2017 [Astro Digital, Inc](https://astrodigital.com/)

Released under the terms of the Simplified BSD License; see the [LICENSE](LICENSE) file for details.

### Author

Michael Toren &lt;mct@toren.net&gt;
