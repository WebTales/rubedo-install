#!/bin/bash
#########################################################################################################################################
# Install-rubedo downloader														#
# This script download and prepare the script to install Rubedo 3.4.x									#
# These components will be downloaded:													#
# install-rubedo-3.4.x.sh	This is the main script											#
# conf				This is a file with configurations									#
# The install script will be started, it needs a Token of Github									#
# Usage:																#
# curl -Ls https://github.com/WebTales/rubedo-docker-public/releases/download/3.4.x/install-rubedo-downloader.sh | sudo -H sh -s Token  #
# Version: 18/02/2016															#
#########################################################################################################################################

set -e # Exit immediately if a command exits with a non-zero status

get_distribution_type()	# Find the distribution type
{
	local lsb_dist
	lsb_dist="$(lsb_release -si 2> /dev/null || echo "unknown")"
	if [ "$lsb_dist" = "unknown" ]; then
		if [ -r /etc/lsb-release ]; then
			lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
		elif [ -r /etc/debian_version ]; then
			lsb_dist='debian'
		elif [ -r /etc/centos-release ]; then
			lsb_dist='centos'
		elif [ -r /etc/redhat-release ]; then
			lsb_dist='rhel'
		elif [ -r /etc/os-release ]; then
			lsb_dist="$(. /etc/os-release && echo "$ID")"
		fi
	fi
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
	echo $lsb_dist
}

clear
echo "Install-rubedo downloader"
echo "WebTales 2017"
echo " "

# Initialisation: verify some parameters before starting the installation
echo "INFO: Initialization..."
if [ $# != 1 ] # Nomber of argument is incorrect
then
	echo "ERROR: Argument number is incorrect"
	echo "Usage: sudo ./script_name Token"
	exit 1
fi

TOKEN_GITHUB_DOWNLOAD=$1
echo "INFO: Token of Github ($TOKEN_GITHUB_DOWNLOAD)"
echo "INFO: Initialization is complete"
echo " "

echo "Installing curl..."
case "$(get_distribution_type)" in
	ubuntu|debian)
		apt-get install -y curl
	;;
	centos|rhel)
		yum install -y curl
	;;
	*)
		echo "ERROR: This script cannot detect the type of distribution or it's not supported"
		echo "Only Debian, Ubuntu, CentOS and Rhel are available for this script"
		exit 1
	;;
esac

echo "INFO: Downloading file (1/2)..."
if [ -f "install-rubedo-3.4.x.sh" ] # If the file is already here
then
	echo "INFO: file is already here"
else
	curl -Lo install-rubedo-3.4.x.sh https://github.com/WebTales/rubedo-docker-public/releases/download/3.4.x/install-rubedo-3.4.x.sh
fi
echo "INFO: The file install-rubedo-3.4.x.sh was downloaded"

echo "INFO: Downloading file (2/2)..."
if [ -f "conf" ] # If the file is already here
then
	echo "INFO: file is already here"
else
	curl -Lo conf https://github.com/WebTales/rubedo-docker-public/releases/download/3.4.x/conf
fi
echo "INFO: The file conf was downloaded"

echo " "

echo "INFO: All files are downloaded"
echo "INFO: The install script will start"
sleep 3

echo "INFO: Starting the script..."
chmod 777 install-rubedo-3.4.x.sh
clear
./install-rubedo-3.4.x.sh conf $TOKEN_GITHUB_DOWNLOAD progress_file
