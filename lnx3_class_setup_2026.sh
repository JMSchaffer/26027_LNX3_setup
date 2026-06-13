#!/bin/bash

_lnx3_setup() {

# Update the CLASS_FOLDER variable to define the directory
# where class materials should be installed.  Edit this appropriately
# for the installation
CLASS_FOLDER="$HOME/26027_LNX3"
CLASS_VENV_DIR="$CLASS_FOLDER/.venv"

# Enter the required Zephyr SDK version for the class. The required version
# can be found in the zephyr_workspace/zephyr/SDK_VERSION file once the 
# examples project is set up.
REQUIRED_ZEPHYR_VERSION="0.17.4"
# Set the path to where the Zephyr SDK will be installed
ZEPHYR_SDK_DIR="/opt"

#----- DO NOT EDIT BELOW THIS LINE -----

# Get the name of the setup directory based on the path to the setup script
SETUP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Set a variable to the name of the directory that will hold the solution images for the labs
IMAGE_DIR="$CLASS_FOLDER/solution_images"

# Ask for the password up-front since we may need to have admin access for some steps
sudo -v

# Keep-alive: update existing sudo time stamp every 60 seconds so that access doesn't expire
# as long as the script is running
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
#trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' RETURN
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# Validate that required companion files exist before proceeding
if [ ! -f "$SETUP_DIR/lnx3_set_env.sh" ]; then
	echo "ERROR: Required file '$SETUP_DIR/lnx3_set_env.sh' not found."
	return 1
fi
if [ ! -f "$SETUP_DIR/pic64gx-zephyr-examples-update-sdk.patch" ]; then
	echo "ERROR: Required file '$SETUP_DIR/pic64gx-zephyr-examples-update-sdk.patch' not found."
	return 1
fi
if [ ! -f "$SETUP_DIR/solution_images/lab3_br_linux_standard_smp.img" ]; then
	echo "ERROR: Required file '$SETUP_DIR/solution_images/lab3_br_linux_standard_smp.img' not found."
	return 1
fi
if [ ! -f "$SETUP_DIR/solution_images/lab4_zephyr_image.bin" ]; then
	echo "ERROR: Required file '$SETUP_DIR/solution_images/lab4_zephyr_image.bin' not found."
	return 1
fi
if [ ! -f "$SETUP_DIR/solution_images/lab5_br_linux_zephyr_amp.img" ]; then
	echo "ERROR: Required file '$SETUP_DIR/solution_images/lab5_br_linux_zephyr_amp.img' not found."
	return 1
fi

# Installation script for 26027 LNX3 class
echo "==========================================="
echo "= Installing 26027 - LNX3 class materials ="
echo "==========================================="

echo
read -r -n 1 -p "Remove ALL existing files and SDKs and install everything with no additional prompts? (y/n): " USER_RESPONSE
echo
# Decide if we want to run in interactive mode or not based on the user response
if [ "$USER_RESPONSE" == "y" ]; then
	# Give the user a chance to confirm a clean install or bail out
	echo
	read -r -n 1 -p "Press y to confirm you want to delete and reinstall all LNX3 materials.  Press q to quit. (y/q): " USER_RESPONSE
	echo
	if [ "$USER_RESPONSE" == "y" ]; then
		# Run all steps automatically with no prompts and remove all materials before starting
		# This is a clean re-install of the class materials.
		INTERACTIVE_MODE="0"
		# set the USER_RESPONSE variable to "y" so that all sections are
		# accepted.
		USER_RESPONSE="y"
	elif [ "$USER_RESPONSE" == "q" ]; then
		echo "======================"
		echo "= Exiting LNX3 Setup ="
		echo "======================"
		return
	fi
else
	# if the user responded with something other than y to the prompt, then we are 
	# going to operate in interactive mode and prompt the user at each step of the install process
	INTERACTIVE_MODE="1"
fi

#======================================================================
# Remove existing class materials and directories before installing
# new materials, if reqired.
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Remove ALL existing class materials in the directory $CLASS_FOLDER before starting? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	# Either the user responded y to remove all materials before starting 
	# or we are not in interactie mode. In either of those cases, we remove
	# all relevant directories before starting.  This is a clean install of
	# the materials.
	echo "Removing $CLASS_FOLDER..."
	rm -rf "$CLASS_FOLDER"
#	echo "Removing ~/zephyrproject..."
#	rm -rf "$HOME/zephyrproject"
#	echo "Removing ~/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION..."
#	rm -rf "$HOME/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION"
	echo "DONE removing existing class materials"
fi



#======================================================================
# install required host system packages
# This section will install all of the Linux packages required for the
# LNX3 class.
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Install required host system packages? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo "Installing required packages"
	echo "============================"
	sudo apt update
	sudo apt-get install --assume-yes --no-install-recommends \
		cmake subversion build-essential bison flex gettext libncurses-dev texinfo \
		autoconf automake libtool mercurial git-core git gperf gawk expat curl cvs \
		libexpat-dev brz unzip bc python3-dev python3-pip python3-setuptools \
		python3-tk python3-wheel python3-venv xz-utils file make gcc gcc-multilib \
		g++-multilib libsdl2-dev libmagic1 dfu-util device-tree-compiler ccache \
		ninja-build wget xxd bmap-tools libyaml-dev libelf-dev zlib1g-dev libssl-dev cpio rsync \
		libgnutls28-dev

  
	sudo apt-get install --assume-yes --no-install-recommends python3-pyelftools python3-packaging python3-pykwalify python3-dateutil python3-ruamel.yaml

	sudo apt-get install --assume-yes --no-install-recommends \
		gcc-multilib g++-multilib

	echo "DONE Installing required packages"
	echo "============================"

fi

#======================================================================
# Apply Ubuntu 24.04 workaround for apparmor
# TODO: Is this required?
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Apply Ubuntu 24.04 workaround? (y/n): " USER_RESPONSE
	echo

fi 
if [ "$USER_RESPONSE" == "y" ]; then
	# workaround for Ubuntu 24.04 issue
	echo "Applying Ubuntu 24.04 workaround"
	echo "================================"
	sudo sysctl kernel.dmesg_restrict=0
	sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
	echo "kernel.apparmor_restrict_unprivileged_userns = 0" | sudo tee /etc/sysctl.d/20-apparmor-donotrestrict.conf
	echo "DONE Applying Ubuntu 24.04 workaround"
	echo "================================"

fi

#======================================================================
# Check to see if the class folder already exists on the host system and if it doesn't,
# create it.  If it does exist already and we are in interactive mode, prompt the user to
# tell us whether to delete it and reinstall or not.
if [ "$INTERACTIVE_MODE" == "1" ]; then
	if [ -d "$CLASS_FOLDER" ]; then
		# We are in interactive mode and the directory exists...ask the user whether to
		# delete it or not.
		echo
		read -r -n 1 -p "Class folder $CLASS_FOLDER already exists.  Delete it? (y/n): " USER_RESPONSE
		echo
		if [ "$USER_RESPONSE" == "y" ]; then
			rm -rf "$CLASS_FOLDER"
		fi
	fi
fi 

if [ ! -d "$CLASS_FOLDER" ]; then
	# If we get here and the folder doesn't exist then create it.  No sense asking the user
	# about it since not much is going to work if we don't create the folder.
	echo "Creating folder: $CLASS_FOLDER"
	echo "=============================="
	mkdir -p "$CLASS_FOLDER"
	
	# Do a check to make sure that the class folder exists now before continuing
	if [ ! -d "$CLASS_FOLDER" ]; then
		# The class folder doesn't exist...exit the script with an error message
		echo "ERROR: The class folder $CLASS_FOLDER does not exist on the host system!"
		return
	else
		echo "DONE Creating: $CLASS_FOLDER"
		echo "=============================="
	fi
else
	echo "Class folder $CLASS_FOLDER already exists.  Continuing with the setup"
fi

# Change directory to the class folder for additional setup
cd "$CLASS_FOLDER" || { echo "ERROR: Failed to change directory to $CLASS_FOLDER"; return 1; }

# Create the solution image directory if it doesn't exist already
if [ ! -d "$IMAGE_DIR" ]; then
	mkdir "$IMAGE_DIR"
fi	

echo "Copying files into the class folder..."
# Copy the set environment shell script to the class folder
cp "$SETUP_DIR/lnx3_set_env.sh" "$CLASS_FOLDER"

# Copy the solution images to the solution images folder
cp "$SETUP_DIR/solution_images/lab3_br_linux_standard_smp.img" "$IMAGE_DIR"
cp "$SETUP_DIR/solution_images/lab4_zephyr_image.bin" "$IMAGE_DIR"
cp "$SETUP_DIR/solution_images/lab5_br_linux_zephyr_amp.img" "$IMAGE_DIR"
echo "DONE"

#======================================================================
# Check to see that the GIT user name and email values are set on this system
# If not set then prompt for them
#if [ "$INTERACTIVE_MODE" == "1" ]; then
#	echo
#	read -r -n 1 -p "Check GIT user name and email? (y/n): " USER_RESPONSE
#	echo
#fi 
#if [ "$USER_RESPONSE" == "y" ]; then
#	echo "Checking GIT USER NAME and EMAIL"
#	echo "================================"
#	# Check if git user.name is set
#	git_user_name=$(git config --get user.name)
#	if [ -z "$git_user_name" ]; then
#		echo "user.name is not set. Please set it now."
#		read -p "Enter your name: " user_name
#		git config --global user.name "$user_name"
#	else
#		echo "GIT user name: $git_user_name"
#	fi
#	
#
#	# Check if git user.email is set
#	git_user_email=$(git config --get user.email)
#	if [ -z "$git_user_email" ]; then
#		echo "user.email is not set. Please set it now."
#		read -p "Enter your email: " user_email
#		git config --global user.email "$user_email"
#	else
#		echo "GIT user email: $git_user_email"
#	fi
#	
#	echo "DONE Checking GIT USER NAME and EMAIL"
#	echo "================================"
#fi

#======================================================================
# Install the main Zephyr sources in the user home directory and set up the 
# correct SDK version required for the PIC64GX examples.  The required version
# can be found in the zephyr_workspace/zephyr/SDK_VERSION file once the 
# examples project is set up.
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Install Zephyr SDK? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Setting up Zephyr SDK"
	echo "================================"
	cd "$HOME" || { echo "ERROR: Failed to change directory to $HOME"; return 1; }
	if [ "$INTERACTIVE_MODE" == "1" ]; then
		# If we are in interactive mode check to see if the directory already exists.  If so then ask
		# the user if it should be deleted and reinstalled.  This will also trigger a re-install of the
		# SDK.
		if [ -d "$ZEPHYR_SDK_DIR/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION" ]; then
			echo
			read -r -n 1 -p "The ZephyrSDK folder already exists.  Delete it and install SDK from scratch? (y/n): " USER_RESPONSE
			echo
			if [ "$USER_RESPONSE" == "y" ]; then
				echo "Removing $ZEPHYR_SDK_DIR/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION"
				sudo rm -rf "$ZEPHYR_SDK_DIR/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION"
			fi
		fi
	fi 

	if [ ! -d "$ZEPHYR_SDK_DIR/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION" ]; then
		# The zephyr SDK directory does not exist so install everything and set up the SDK.
		if [ ! -d "$CLASS_VENV_DIR" ]; then
			python3 -m venv "$CLASS_VENV_DIR"
		fi
		source "$CLASS_VENV_DIR/bin/activate"
		pip install west
		cd "$HOME" || { echo "ERROR: Failed to change directory to $HOME"; return 1; }
		echo
		echo "Installing Zephyr SDK v$REQUIRED_ZEPHYR_VERSION"
		echo "================================"
		echo "Downloading the SDK"
		wget "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${REQUIRED_ZEPHYR_VERSION}/zephyr-sdk-${REQUIRED_ZEPHYR_VERSION}_linux-x86_64.tar.xz"
		echo "Extracting the SDK"
		sudo tar xvf "zephyr-sdk-${REQUIRED_ZEPHYR_VERSION}_linux-x86_64.tar.xz" -C "$ZEPHYR_SDK_DIR/"
		echo "Installing the SDK"
		cd "$ZEPHYR_SDK_DIR/zephyr-sdk-${REQUIRED_ZEPHYR_VERSION}" || { echo "ERROR: Failed to change directory to $ZEPHYR_SDK_DIR/zephyr-sdk-${REQUIRED_ZEPHYR_VERSION}"; return 1; }
		./setup.sh -t riscv64-zephyr-elf -h -c
		cd "$HOME" || { echo "ERROR: Failed to change directory to $HOME"; return 1; }
		rm -rf "zephyr-sdk-${REQUIRED_ZEPHYR_VERSION}_linux-x86_64.tar.xz"
	else
		echo "Zephyr SDK already installed"
	fi
	
	export ZEPHYR_SDK_INSTALL_DIR="$ZEPHYR_SDK_DIR/zephyr-sdk-$REQUIRED_ZEPHYR_VERSION"
	
	if "${ZEPHYR_SDK_INSTALL_DIR}/riscv64-zephyr-elf/bin/riscv64-zephyr-elf-gcc" --version >/dev/null 2>&1; then
		echo "Zephyr SDK cross-compiler is fully accessible and executable!"
	else
		echo "ERROR: Zephyr SDK binaries are missing or not executable."
		return
	fi
	
	echo "DONE Setting up Zephyr SDK"
	echo "================================"
#

fi

#======================================================================
# Download the source code for Hart Software Services, the bootloader used by the PIC64GX1000.
# We will need to build the HSS payload generator tool from sources so that it can be used
# to create payloads to boot on the Curiosity kit.
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Download HSS sources and build Payload Generator? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Downloading HSS Sources"
	echo "================================"
	cd "$CLASS_FOLDER" || { echo "ERROR: Failed to change directory to $CLASS_FOLDER"; return 1; }
	if [ "$INTERACTIVE_MODE" == "1" ]; then
		# If in interactive mode and the destination directory already exists, ask the user
		# whether it should be deleted and reinstalled.
		if [ -d "$CLASS_FOLDER/hart-software-services/" ]; then
			echo
			read -r -n 1 -p "The $CLASS_FOLDER/hart-software-services/ folder already exists.  Delete it and reinstall? (y/n): " USER_RESPONSE
			echo
			if [ "$USER_RESPONSE" == "y" ]; then
				rm -rf "$CLASS_FOLDER/hart-software-services/"
			fi
		fi
	fi 

	if [ ! -d "$CLASS_FOLDER/hart-software-services/" ]; then
		#if the directory is not present, download the sources
		wget https://github.com/pic64gx/pic64gx-hart-software-services/archive/refs/heads/pic64gx.zip -O hss.zip
		unzip ./hss.zip -d hart-software-services
		rm ./hss.zip
	fi

	# Build the HSS Payload Generator tool
	echo
	echo "Building HSS Payload Generator"
	echo "================================"
	cd "$CLASS_FOLDER/hart-software-services/pic64gx-hart-software-services-pic64gx/tools/hss-payload-generator" || { echo "ERROR: Failed to change directory to hss-payload-generator"; return 1; }
	make

	# Sanity check to make sure the build completed successfully and created the binary for the tool
	if [ -f "$CLASS_FOLDER/hart-software-services/pic64gx-hart-software-services-pic64gx/tools/hss-payload-generator/hss-payload-generator" ]; then
		echo "DONE with HSS setup"
		echo "================================"
	else
		echo "ERROR: hss-payload-generator executable not detected...exiting setup script"
		return
	fi
fi

#======================================================================
# Clone the PIC64GX Zephyr examples repository and build the Zephyr 'button' example 
# application for the PIC64GX Curiosity Kit
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Clone sources and build the PIC64GX Zephyr 'button' example app? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Building PIC64GX Button Zephyr example"
	echo "================================"
	source "$CLASS_FOLDER/lnx3_set_env.sh"
	cd "$CLASS_FOLDER" || { echo "ERROR: Failed to change directory to $CLASS_FOLDER"; return 1; }
	if [ "$INTERACTIVE_MODE" == "1" ]; then
		if [ -d "$CLASS_FOLDER/zephyr_workspace/" ]; then
			# The zephyr_workspace directory already exists...ask the user if they want to delete it and reinstall
			# or just use what's there
			echo
			read -r -n 1 -p "The $CLASS_FOLDER/zephyr_workspace/ folder already exists.  Delete it and reinstall? (y/n): " USER_RESPONSE
			echo
			if [ "$USER_RESPONSE" == "y" ]; then
				rm -rf "$CLASS_FOLDER/zephyr_workspace/"
				unset ZEPHYR_BASE
			fi
		fi
	fi 
	
	if [ ! -d "$CLASS_FOLDER/zephyr_workspace/" ]; then
		# The zephyr_workspace directory doesn't exist...clone the repo and build the example
		if [ ! -d "$CLASS_VENV_DIR" ]; then
			python3 -m venv "$CLASS_VENV_DIR"
		fi
		source "$CLASS_VENV_DIR/bin/activate"
		unset ZEPHYR_BASE
		pip install west
		mkdir zephyr_workspace && cd zephyr_workspace || { echo "ERROR: Failed to create/enter zephyr_workspace"; return 1; }
		echo "================================"
		echo "Cloning the PIC64GX Zephyr Examples repo"
		git clone https://github.com/pic64gx/pic64gx-zephyr-examples.git -b pic64gx pic64gx-soc
		cd pic64gx-soc || { echo "ERROR: Failed to change directory to pic64gx-soc"; return 1; }
		echo "================================"
		echo "Patching the PIC64GX Zephyr Examples for updated SDK"
		git apply "$SETUP_DIR/pic64gx-zephyr-examples-update-sdk.patch"
		west init -l
		cd ../ || { echo "ERROR: Failed to change directory to parent"; return 1; }
		west update
		pip install -r "zephyr/scripts/requirements.txt"
		west packages pip --install
		west zephyr-export
		source zephyr/zephyr-env.sh
		west blobs fetch
		west build -p -b pic64gx_curiosity_kit pic64gx-soc/apps/button
		# Deactivate the python virtual environment since we're done building the zephyr project
		deactivate
	else
		echo "zephyr_workspace already exists...not rebuilding"
	fi
	
	# Sanity check to make sure that the Zephyr build completed and the .elf file output is present in the build directory
	if [ -f "$CLASS_FOLDER/zephyr_workspace/build/zephyr/zephyr.elf" ]; then
#		"$CLASS_FOLDER/hart-software-services/pic64gx-hart-software-services-pic64gx/tools/hss-payload-generator/hss-payload-generator" -c "$CLASS_FOLDER/zephyr_workspace/pic64gx-soc/payload-configs/single_hart_ddr.yaml" "$IMAGE_DIR/lab4_zephyr_image.bin"
#		if [ -f "$IMAGE_DIR/lab4_zephyr_image.bin" ]; then
			echo "DONE Building PIC64GX Button Zephyr example"
			echo "================================"
#		else
#			echo "ERROR: Zephyr Button example HSS payload binary file does not exist...exiting setup script."
#			return
#		fi
	else
		echo "ERROR: Zephyr Button example .elf output file does not exist...exiting setup script."
		return
	fi
fi

#======================================================================
# Clone the buildroot-external-microchip and buildroot repositories required for building
# Linux images for the board using the buildroot build system.
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Clone the repositories for buildroot-external-microchip builds? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Cloning repos for buildroot-external-microchip"
	echo "================================"
	cd "$CLASS_FOLDER" || { echo "ERROR: Failed to change directory to $CLASS_FOLDER"; return 1; }
	if [ "$INTERACTIVE_MODE" == "1" ]; then
		# if in interactive mode, check for the existence of the directories required for buildroot builds.  If they
		# are there then prompt the user to see if they want to delete and reinstall.
		if [ -d "$CLASS_FOLDER/buildroot/" ]; then
			echo
			read -r -n 1 -p "The $CLASS_FOLDER/buildroot/ folder already exists.  Delete it and reinstall? (y/n): " USER_RESPONSE
			echo
			if [ "$USER_RESPONSE" == "y" ]; then
				rm -rf "$CLASS_FOLDER/buildroot/"
			fi
		fi
		if [ -d "$CLASS_FOLDER/buildroot-external-microchip/" ]; then
			echo
			read -r -n 1 -p "The $CLASS_FOLDER/buildroot-external-microchip/ folder already exists.  Delete it and reinstall? (y/n): " USER_RESPONSE
			echo
			if [ "$USER_RESPONSE" == "y" ]; then
				rm -rf "$CLASS_FOLDER/buildroot-external-microchip/"
			fi
		fi
	fi 
	
	# Clone the appropriate repos if they do not exist
	if [ ! -d "$CLASS_FOLDER/buildroot/" ]; then
		git clone https://git.busybox.net/buildroot -b 2025.02
	fi
	if [ ! -d "$CLASS_FOLDER/buildroot-external-microchip/" ]; then
		git clone https://github.com/linux4microchip/buildroot-external-microchip.git -b linux4microchip-2025.10
	fi
	echo "DONE Cloning repos for buildroot-external-microchip"
	echo "================================"

fi

#======================================================================
# Build the default buildroot Linux image for the PIC64GX Curiosity kit and
# copy the resulting image to the class folder to archive it there
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo 
	read -r -n 1 -p "Set up for the PIC64GX Curiosity board default Linux image? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Downloading sources for the PIC64GX Curiosity board default buildroot image"
	echo "================================"
	cd "$CLASS_FOLDER/buildroot/" || { echo "ERROR: Failed to change directory to $CLASS_FOLDER/buildroot/"; return 1; }
	export BR2_EXTERNAL=../buildroot-external-microchip/ 
	make clean
	make pic64gx_curiosity_kit_defconfig
	#make
	make source
	STATUS=$?
	if [ $STATUS -eq 0 ]; then
		echo "SUCCESS: buildroot default Downloads verified"
	else
		echo "ERROR buildroot default downloads failed"
		return
	fi
#	# Sanity check to make sure the linux image has been generated by the build
#	if [ -f "./output/images/sdcard.img" ]; then
#		echo
#		echo "Saving the default buildroot image to the class folder"
#		echo "================================"
#		mv ./output/images/sdcard.img "$IMAGE_DIR/lab3_br_linux_standard_smp.img"
#		
#		echo "DONE Building the PIC64GX Curiosity board default buildroot image"
#		echo "================================"
#	else
#		echo "ERROR: Default Linux image was not found.  See build output for details."
#		return
#	fi

fi	

#======================================================================
# Build the default buildroot Linux image for the PIC64GX Curiosity kit and
# copy the resulting image to the class folder to archive it there
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Set up for PIC64GX Curiosity board AMP Linux image? (y/n): " USER_RESPONSE
	echo
fi 
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Downloading sources for the PIC64GX Curiosity board AMP buildroot image"
	echo "================================"
	cd "$CLASS_FOLDER/buildroot/" || { echo "ERROR: Failed to change directory to $CLASS_FOLDER/buildroot/"; return 1; }
	export BR2_EXTERNAL=../buildroot-external-microchip/ 
	make clean
	make pic64gx_curiosity_kit_amp_defconfig
	#make
	make source
	STATUS=$?
	if [ $STATUS -eq 0 ]; then
		echo "SUCCESS: AMP Downloads verified"
	else
		echo "ERROR buildroot AMP downloads failed"
		return
	fi
#	# Sanity check to make sure the linux image has been generated by the build
#	if [ -f "./output/images/sdcard.img" ]; then
#		echo
#		echo "Saving the default buildroot image to the class folder"
#		echo "================================"
#		mv ./output/images/sdcard.img "$IMAGE_DIR/lab5_br_linux_zephyr_amp.img"
#		
#		echo "DONE Building the PIC64GX Curiosity board AMP buildroot image"
#		echo "================================"
#
#	else
#		echo "ERROR: AMP Linux image was not found.  See build output for details."
#		return
#	fi
fi

#======================================================================
# Download the ubuntu image for restoring the initial out-of-box state
# for the PIC64GX1000 Curiosity Kit
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Download a backup copy of the Ubuntu image to the solutions directory? (y/n): " USER_RESPONSE
	echo
fi
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Downloading the PIC64GX Ubuntu image..."
	echo "================================"
	cd "$IMAGE_DIR" || { echo "ERROR: Failed to change directory to $IMAGE_DIR for Ubuntu backup image download"; return 1; }
	wget https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.4-preinstalled-server-riscv64+pic64gx.img.xz

	if [ -f "$IMAGE_DIR/ubuntu-24.04.4-preinstalled-server-riscv64+pic64gx.img.xz" ]; then
		echo "DONE downloading the Ubuntu image"
		echo "================================"
	else
		echo "ERROR: Ubuntu backup image not downloaded"
		return
	fi
fi

#======================================================================
# Download the ubuntu image for restoring the initial out-of-box state
# for the PIC64GX1000 Curiosity Kit
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Download a backup copy of the Ubuntu image to the solutions directory? (y/n): " USER_RESPONSE
	echo
fi
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Downloading the image..."
	echo "================================"
	cd "$IMAGE_DIR" || { echo "ERROR: Failed to change directory to $IMAGE_DIR for Ubuntu backup image download"; return 1; }
	wget https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.4-preinstalled-server-riscv64+pic64gx.img.xz

	if [ -f "$IMAGE_DIR/ubuntu-24.04.4-preinstalled-server-riscv64+pic64gx.img.xz" ]; then
		echo "DONE downloading the Ubuntu image"
		echo "================================"
	else
		echo "ERROR: Ubuntu backup image not downloaded"
		return
	fi
fi

#======================================================================
# Install udev rules
if [ "$INTERACTIVE_MODE" == "1" ]; then
	echo
	read -r -n 1 -p "Install udev rules? (y/n): " USER_RESPONSE
	echo
fi
if [ "$USER_RESPONSE" == "y" ]; then
	echo
	echo "Installing udev rules"
	echo "================================"
	source "$SETUP_DIR/install_udev.sh"
	echo "DONE Installing udev rules"
	echo "================================"
fi

echo "=========================="
echo "=  DONE with LNX3 SETUP  ="
echo "=========================="

# Go back to the user's home directory
cd ~

return

}
_lnx3_setup "$@"
