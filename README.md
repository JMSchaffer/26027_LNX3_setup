# LNX3 MASTERS Class setup materials 2026

This repository contains setup scripts and materials for the LNX3 MASTERs Class for 2026

## Setup
To set up a new host machine for the class:
- Clone this repository to the local machine
- Review the configuration items at the top of lnx3_class_setup_2026.sh and edit if necessary for the desired installation
- Run the script: source lnx3_class_setup_2026.sh
	- It will first ask if you want to delete any existing materials and install everything from scratch.  Answer y to delete anything that exists in the class directory and reinstall everything.
 	- If you answer n then the script will ask you about installing each component.  You can use this to try the individual components.
- Check for any errors reported
- The setup script clones all necessary repositories at the required commits, applies any necessary patches, and builds all images to test the installation.
- Solution images are stored in a separate directory under the class directory.
- The setup performs full buildroot Linux builds so that all required data is downloaded to the host so that all downloads are present on the lab machine.
- Setup can take a couple hours due to generating the Linux solution images.
- The result of successful script completion is that your machine should be set up identically to how a masters Linux lab machine will be set up.


## Files
- lnx3_class_setup_2026.sh - Shell script that will clone all class materials for LNX3.  This is the script that will be run on the ghosting machines to set up for the class.
- lnx3_set_env.sh - Shell script that will set the environment for building class labs.  Must be run each time a new shell is opened.
- install_udev.sh - Installs a udev rule so that the host machine can access the serial ports provided by the PIC64GX Discovery Kit.
- pic64gx-zephyr-examples-update-sdk.patch - Patch file applied to the PIC64GX Zephyr examples repository to make the projects compatible with the standard Zephyr SDK version used for MASTERs (v0.17.4)

## Notes
- The build can be tested with WSL under Windows if a Linux machine is not available (use a Ubuntu-24.04 distribution when creating the WSL image)
	- Add the following to your /etc/wsl.conf to remove the windows path from the Linux path (causes problems with the build tools because of spaces in the Windows path)
	```
	[interop]
	appendWindowsPath = false
	```
- Using a card reader with WSL has not been tested and may be problematic due to IT policies.
- Paths shown in the lab manual might be different for SD cards/card readers under WSL
