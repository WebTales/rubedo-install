#!/bin/bash
#############################################################################################################################
# Installation agent for Rubedo 3.4.x                     		      			 		                         			#
# This agent will follow these steps:					     					                                 			#
# 1) MongoDB	                                        		     					 						 			#
# 2) Java environment & Elasticsearch                   		     					                         			#
# 3) PHP and Apache                             						 		                                 			#
# 4) Rubedo and git							     																 			#
# For more details: http://docs.rubedo-project.org/en/homepage/install-rubedo 			 		 							#
# Compatibility: Ubuntu 16.04 Ubuntu 14.04 Trusty Tahr, Ubuntu 12.04 Precise Pangolin, Debian 7 Wheezy, CentOS 7 and Rhel   #
# Script for a 64 bits distribution                                                                              			#
# Don't edit this script! Please edit the configuration file: data comes from this file	         		 					#
# Usage: sudo ./script_name configuration_file token progress_file						 									#
# configuration_file: file with configurations									 											#
# token: Token of Github (go to your Github account)								 										#
# progress_file: file with progression (if you want to resume after an error for example)			 						#
# Version: 27/03/2016												 														#
#############################################################################################################################

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

load_config() # Load configurations from the configuration file
{
	count_line=`sed -n '$=' $CONFIGURATION_FILE`
	for i in `seq 1 $count_line`;
	do
       		temp=`sed -n ${i}p $CONFIGURATION_FILE`
		temp=`echo $temp|cut -d"=" -f2`
		if [ -z "$temp" ]
		then
			echo -ne "\n"
			echo "ERROR: The configuration file is invalid"
			echo "Please verify this file: $CONFIGURATION_FILE"
			exit 1
		fi
		pourcentage=$(($i * 100 / $count_line))
		echo -ne "INFO: Loading configurations: $i/$count_line -> $pourcentage%\r"
	done
	cluster_name="$RANDOM.$USER"
	link_script=`echo $(pwd)`
	source $CONFIGURATION_FILE
	echo -ne "INFO: Loading configurations: $i/$count_line -> $pourcentage% DONE\n"
	unset i && unset temp && unset pourcentage && unset count_line
}

init_progress() # Initialize a progress file
{
	touch $PROGRESS_FILE
	echo "ID=$ID_FILE" >> $PROGRESS_FILE
	for i in `seq 1 19`;
	do
		echo "STEP_$i=0" >> $PROGRESS_FILE
	done
	unset i
}

verif_progress() # Verify that the progress file is correct
{
	count_line=`sed -n '$=' $PROGRESS_FILE`
	for i in `seq 1 $count_line`;
	do
       		temp=`sed -n ${i}p $PROGRESS_FILE`
		temp=`echo $temp|cut -d"=" -f2`
		if [ -z "$temp" ]
		then
			echo -ne "\n"
			echo "ERROR: The progress file is invalid"
			echo "Please verify this file: $PROGRESS_FILE"
			exit 1
		fi
		pourcentage=$(($i * 100 / $count_line))
		echo -ne "INFO: Loading progression: $i/$count_line -> $pourcentage%\r"
	done
	echo -ne "INFO: Loading progression: $i/$count_line -> $pourcentage% DONE\n"
	unset i && unset temp && unset pourcentage && unset count_line
}

if [ -f "logo" ]
then
	cat "logo"
	echo " "
fi
echo "Installation agent for Rubedo 3.4.x"
echo "WebTales 2017, Antoine LASSERRE"
echo " "

# Initialisation: verify some parameters before starting the installation
echo "INFO: Initialization..."
if [ $# != 3 ] # Nomber of argument is incorrect
then
	echo "ERROR: Argument number is incorrect"
	echo "Usage: sudo ./script_name configuration_file token progress_file"
	exit 1
fi

CONFIGURATION_FILE=$1
if [ -f $CONFIGURATION_FILE ] # File $1 found
then
	echo "INFO: Configuration file ($CONFIGURATION_FILE)"
	load_config $CONFIGURATION_FILE
else
   	echo "ERROR: Configuration file not found"
	echo "Please verify this path: $CONFIGURATION_FILE"
	exit 1
fi

TOKEN_GITHUB=$2
echo "INFO: Token of Github ($TOKEN_GITHUB)"


PROGRESS_FILE=$3
if [ -f $PROGRESS_FILE ] # File $3 found
then
	echo "INFO: Resume an installation"
	source $PROGRESS_FILE
else
	echo "INFO: Starting the script from a blank system"
	init_progress $PROGRESS_FILE
	source $PROGRESS_FILE
fi
verif_progress $PROGRESS_FILE
if [ $ID_FILE != $ID ]
then
	echo "ERROR: ID of this script ($ID_FILE) and ID of progress file ($ID) are different"
	echo "Big issues are possible with different IDs, installation is interrupted"
	exit 1
fi
temp_tab=( 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 )
for i in `seq 0 18`;
do
	j=$(($i+1))
	temp="STEP_$j"
	temp_tab[$i]="$(eval echo \$$temp)"
done
echo "INFO: Current installation (${temp_tab[*]})"
unset temp_tab && unset i && unset j && unset temp

if [ "$(uname -m)" != "x86_64" ] # Architecture is not supported
then
	echo "ERROR: Unsupported architecture: $(uname -m)"
	echo "This script is for a 64 bits distribution"
	exit 1
fi
echo "INFO: Architecture ($(uname -m))"
echo "INFO: Initialization is complete"
echo -ne "Starting up in 3...\r"
sleep 1
echo -ne "Starting up in 2...\r"
sleep 1
echo -ne "Starting up in 1...\r"
sleep 1
echo -ne "Starting up...     \r"
echo -ne "\n"
echo " "

echo "INFO: Type of distribution ($(get_distribution_type))"

case "$(get_distribution_type)" in
	ubuntu|debian)
		echo "INFO: Type of distribution is correct, the setup agent will continue"

		case "$(get_distribution_type)" in
                        ubuntu)
				version=`sed -n 2p /etc/lsb-release`
                        ;;
                        debian)
				version=`sed -n 1p /etc/issue`
                        ;;
		esac

		echo "INFO: Step 1: MongoDB"
		if [ $STEP_1 -eq 0 ]
		then
			echo "INFO: Import the public key used by the package management system..."
			apt-key adv --keyserver $MONGODB_PUBLICKEY_KEYSERVER_ALLDEB --recv $MONGODB_PUBLICKEY_RECV_ALLDEB
			sed -i 's/STEP_1=0/STEP_1=1/' $PROGRESS_FILE
		fi
		if [ $STEP_2 -eq 0 ]
		then
			echo "INFO: Create a list file for MongoDB..."
			echo "INFO: Distribution release ($version)"
			case "$version" in # Détection de la version
				"DISTRIB_RELEASE=16.04")
					echo "deb $MONGODB_LISTFILE_UBUNTU16_DEB" | tee $MONGODB_LISTFILE_ALLDEB_TEE
				;;
				"DISTRIB_RELEASE=14.04")
					echo "deb $MONGODB_LISTFILE_UBUNTU14_DEB" | tee $MONGODB_LISTFILE_ALLDEB_TEE
				;;
				"DISTRIB_RELEASE=12.04")
					echo "deb $MONGODB_LISTFILE_UBUNTU12_DEB" | tee $MONGODB_LISTFILE_ALLDEB_TEE
				;;
				"Debian GNU/Linux 7 \n \l")
					echo "deb $MONGODB_LISTFILE_DEBIAN7_DEB" | tee $MONGODB_LISTFILE_ALLDEB_TEE
				;;
				*)
					echo "ERROR: Version not supported"
					echo "For more details: $DOCUMENTATION_SETUP_URL"
					exit 1
				;;
			esac
			sed -i 's/STEP_2=0/STEP_2=1/' $PROGRESS_FILE
		fi
		if [ $STEP_3 -eq 0 ]
		then
			echo "INFO: Reload local package database..."
			apt-get update
			echo "INFO: Installation of the MongoDB packages..."
			apt-get install -y $MONGODB_PACKAGES_ALL
			sed -i 's/STEP_3=0/STEP_3=1/' $PROGRESS_FILE
		fi
		echo "INFO: Restarting MongoDB..."
		service mongod restart
		echo "INFO: Installation of MongoDB is completed"

		echo "INFO: Step2: Java environment & Elasticsearch"
		if [ $STEP_4 -eq 0 ]
		then
			echo "INFO: Installation of Java environment..."
			apt-get install -y $OPENJDK_PACKAGES_ALLDEB # Openjdk >= 7.x is needed
			echo "INFO: Updating Java environment..."
			update-java-alternatives -s $OPENJDK_UPDATE_ALLDEB # Choose openjdk-7 as a default version
			sed -i 's/STEP_4=0/STEP_4=1/' $PROGRESS_FILE
		fi
		if [ $STEP_5 -eq 0 ]
		then
			echo "INFO: Import the public key used by the package management system..."
			wget -qO - $ELASTICSEARCH_PUBLICKEY_WGET_ALLDEB | apt-key add -
			sed -i 's/STEP_5=0/STEP_5=1/' $PROGRESS_FILE
		fi
		if [ $STEP_6 -eq 0 ]
		then
			echo "INFO: Create a list file for Elasticsearch..."
			echo "deb $ELASTICSEARCH_LISTFILE_ALLDEB" | tee -a $ELASTICSEARCH_LISTFILE_TEE_ALLDEB
			sed -i 's/STEP_6=0/STEP_6=1/' $PROGRESS_FILE
		fi

		if [ $STEP_7 -eq 0 ]
		then
			echo "INFO: Reload local package database..."
			apt-get update
			echo "INFO: Installation of the Elasticsearch packages..."
                	apt-get install -y $ELASTICSEARCH_PACKAGES_ALL
			sed -i 's/STEP_7=0/STEP_7=1/' $PROGRESS_FILE
		fi
		if [ $STEP_8 -eq 0 ]
		then
			echo "INFO: Installation of plugins (1/2)..."
			$ELASTICSEARCH_PLUGIN_ONE_ALL
			sed -i 's/STEP_8=0/STEP_8=1/' $PROGRESS_FILE
		fi
		if [ $STEP_9 -eq 0 ]
		then
			echo "INFO: Installation of plugins (2/2)..."
			$ELASTICSEARCH_PLUGIN_TWO_ALL
			sed -i 's/STEP_9=0/STEP_9=1/' $PROGRESS_FILE
		fi
		if [ $STEP_10 -eq 0 ]
		then
			echo "INFO: Configuring Elasticsearch..."
			sed -i "$ELASTICSEARCH_CLUSTERNAME_REPLACEMENT" $ELASTICSEARCH_CONFIG_LINK
			sed -i "$ELASTICSEARCH_BINDHOST_REPLACEMENT" $ELASTICSEARCH_CONFIG_LINK
			update-rc.d $ELASTICSEARCH_AUTOLOAD_ALLDEB
			echo "INFO: Cluster.name: $cluster_name, host: 127.0.0.1, automatic start up activated"
			sed -i 's/STEP_10=0/STEP_10=1/' $PROGRESS_FILE
		fi
		echo "INFO: Restarting Elasticsearch..."
		/etc/init.d/elasticsearch restart
		echo "INFO: Installation of Elasticsearch is completed"

		echo "INFO: Step3: PHP"
		if [ $STEP_11 -eq 0 ]
		then
			echo "INFO: Installation of the PHP packages..."
			echo "INFO: Distribution release ($version)"
                	case "$version" in # Détection de la version
							"DISTRIB_RELEASE=16.04")
					apt-get install -y $PHP_PACKAGES_UBUNTU16
							;;
                        	"DISTRIB_RELEASE=14.04")
					apt-get install -y $PHP_PACKAGES_UBUNTU14
                        	;;
                        	"DISTRIB_RELEASE=12.04")
					sudo add-apt-repository -y $PHP_ADDREPOSITORY # Default version of PHP is 5.3.x, or >= 5.4.x is needed
					apt-get update
                                	apt-get install -y $PHP_PACKAGES_UBUNTU12_DEBIAN
					pecl install -f $PHP_PECL_PACKAGES # Php5-mongo does not exist for apt-get in Ubuntu 12.04 LTS
					touch $PHP_CONFIG_LINK_ALLDEB
					echo "$PHP_CONFIG_WRITE" >> $PHP_CONFIG_LINK_ALLDEB
                       	 	;;
                        	"Debian GNU/Linux 7 \n \l")
					apt-get install -y $PHP_PACKAGES_UBUNTU12_DEBIAN
					pecl install -f $PHP_PECL_PACKAGES # Php5-mongo does not exist for apt-get in Debian 7
					touch $PHP_CONFIG_LINK_ALLDEB
					echo "$PHP_CONFIG_WRITE" >> $PHP_CONFIG_LINK_ALLDEB
                        	;;
                        	*)
                                	echo "ERROR: Version not supported"
                                	echo "For more details: $DOCUMENTATION_SETUP_URL"
                                	exit 1
                        	;;
                	esac
			sed -i 's/STEP_11=0/STEP_11=1/' $PROGRESS_FILE
		fi
                if [ $STEP_12 -eq 0 ]
		then
			echo "INFO: Configuring PHP..."
			sed -i "$PHP_CONFIG_TIMEZONE_REPLACEMENT_ALLDEB" $PHP_CONFIG_LINK_PHPINI_ALLDEB
			sed -i 's/STEP_12=0/STEP_12=1/' $PROGRESS_FILE
		fi
		echo "INFO: Installation of PHP is completed"

		echo "INFO: Step4: Rubedo"
		if [ $STEP_13 -eq 0 ]
		then
			echo "INFO: Installation of Git..."
			apt-get install -y $GIT_PACKAGES_ALL
			sed -i 's/STEP_13=0/STEP_13=1/' $PROGRESS_FILE
		fi
		if [ $STEP_14 -eq 0 ]
		then
			echo "INFO: Cloning Rubedo..."
			git clone -b "$GIT_CLONE_VERSION" $GIT_CLONE_LINK
			sed -i 's/STEP_14=0/STEP_14=1/' $PROGRESS_FILE
		fi
		if [ $STEP_15 -eq 0 ]
		then
			echo "INFO: Configuring Apache..."
			case "$version" in # Détection de la version
				"DISTRIB_RELEASE=16.04")
					temp_tab=( ONE TWO THREE FOUR FIVE SIX )
					for a in `seq 0 5`;
					do
						temp="APACHE_UBUNTU16_REPLACEMENT_${temp_tab[$a]}"
						sed -i "$(eval echo \$$temp)" $APACHE_UBUNTU16_LINK
					done
					unset a && unset temp && unset temp_tab
				;;
				"DISTRIB_RELEASE=14.04")
					temp_tab=( ONE TWO THREE FOUR FIVE SIX )
					for a in `seq 0 5`;
					do
						temp="APACHE_UBUNTU14_REPLACEMENT_${temp_tab[$a]}"
						sed -i "$(eval echo \$$temp)" $APACHE_UBUNTU14_LINK
					done
					unset a && unset temp && unset temp_tab
				;;
				"DISTRIB_RELEASE=12.04")
					temp_tab=( ONE TWO THREE FOUR FIVE )
					for a in `seq 0 4`;
					do
						temp="APACHE_UBUNTU12_DEBIAN_REPLACEMENT_${temp_tab[$a]}"
						sed -i "$(eval echo \$$temp)" $APACHE_UBUNTU12_DEBIAN_LINK
					done
					unset a && unset temp && unset temp_tab
				;;
				"Debian GNU/Linux 7 \n \l")
					temp_tab=( ONE TWO THREE FOUR FIVE )
					for a in `seq 0 4`;
					do
						temp="APACHE_UBUNTU12_DEBIAN_REPLACEMENT_${temp_tab[$a]}"
						sed -i "$(eval echo \$$temp)" $APACHE_UBUNTU12_DEBIAN_LINK
					done
					unset a && unset temp && unset temp_tab
				;;
				*)
					echo "ERROR: Version not supported"
					echo "For more details: $DOCUMENTATION_SETUP_URL"
					exit 1
				;;
			esac
			sed -i 's/STEP_15=0/STEP_15=1/' $PROGRESS_FILE
		fi
		if [ $STEP_16 -eq 0 ]
		then
			a2enmod rewrite
			temp_tab=( ONE TWO THREE )
			for a in `seq 0 2`;
			do
				temp="APACHE_ALLDEB_CONF_REPLACEMENT_${temp_tab[$a]}"
				sed -i "$(eval echo \$$temp)" $APACHE_ALLDEB_CONF_LINK
			done
			unset a && unset temp && unset temp_tab
			sed -i 's/STEP_16=0/STEP_16=1/' $PROGRESS_FILE
		fi
		if [ $STEP_17 -eq 0 ]
		then
			echo "INFO: Adding a new host..."
			sed -i "$APACHE_NEWHOST_REPLACEMENT_ALL" $APACHE_NEWHOST_LINK_ALL
			sed -i 's/STEP_17=0/STEP_17=1/' $PROGRESS_FILE
		fi
		if [ $STEP_18 -eq 0 ]
		then
			echo "INFO: Installing and preparing composer..."
			curl -sS $COMPOSER_LINK | php -- --install-dir=$COMPOSER_DESTINATION
			cd $COMPOSER_DESTINATION
   			php $COMPOSER_FILE config -g $COMPOSER_WEBSITEGIT "$TOKEN_GITHUB"
			cd $link_script
			sed -i 's/STEP_18=0/STEP_18=1/' $PROGRESS_FILE
		fi
		echo "INFO: Running composer..."
		cd $COMPOSER_DESTINATION
		$RUBEDO_INSTALL_SCRIPT
		cd $link_script
		if [ $STEP_19 -eq 0 ]
		then
			echo "INFO: Preparing the installation page..."
			temp_tab=( ONE TWO )
			for a in `seq 0 1`;
			do
				temp="INSTALL_REPLACEMENT_${temp_tab[$a]}"
				sed -i "$(eval echo \$$temp)" $INSTALL_LINK
			done
			unset a && unset temp && unset temp_tab
			sed -i 's/STEP_19=0/STEP_19=1/' $PROGRESS_FILE
		fi
		echo "INFO: Restarting Apache..."
		service apache2 restart
		echo "INFO: Installation of Rubedo is completed"
	;;
	centos|rhel)
		echo "INFO: Type of distribution is correct, the setup agent will continue"

		echo "INFO: Step 1: MongoDB"
		if [ $STEP_1 -eq 0 ]
		then
			echo "INFO: Configuring the package management system..."
			touch $MONGODB_REPO
			temp_tab=( ONE TWO THREE FOUR FIVE )
			for a in `seq 0 4`;
			do
				temp="MONGODB_REPOSITORY_WRITE_${temp_tab[$a]}"
				echo "$(eval echo \$$temp)" >> $MONGODB_REPOSITORY_WRITE_LINK
			done
			unset a && unset temp && unset temp_tab
			sed -i 's/STEP_1=0/STEP_1=1/' $PROGRESS_FILE
		fi

		if [ $STEP_2 -eq 0 ]
		then
			echo "INFO: Reload local package database..."
			yum -y update
			echo "INFO: Installing the MongoDB packages and associated tools..."
			yum install -y $MONGODB_PACKAGES_ALL
			sed -i 's/STEP_2=0/STEP_2=1/' $PROGRESS_FILE
		fi
		echo "INFO: Starting MongoDB..."
		service mongod start
		echo "INFO: Installation of MongoDB is completed"

		echo "INFO: Step2: Java environment & Elasticsearch"
		if [ $STEP_3 -eq 0 ]
		then
			echo "INFO: Installation of Java environment..."
			yum install -y $OPENJDK_PACKAGES_CENTOS # Openjdk >= 7.x is needed
			sed -i 's/STEP_3=0/STEP_3=1/' $PROGRESS_FILE
		fi
		if [ $STEP_4 -eq 0 ]
		then
			echo "INFO: Downloading and installing the Public Signing Key..."
			rpm --import $ELASTICSEARCH_PUBLICKEY_CENTOS
			sed -i 's/STEP_4=0/STEP_4=1/' $PROGRESS_FILE
		fi
		if [ $STEP_5 -eq 0 ]
		then
			echo "INFO: Configuring the package management system..."
			touch $ELASTICSEARCH_REPO
			temp_tab=( ONE TWO THREE FOUR FIVE SIX )
			for a in `seq 0 5`;
			do
				temp="ELASTICSEARCH_REPOSITORY_WRITE_${temp_tab[$a]}"
				echo "$(eval echo \$$temp)" >> $ELASTICSEARCH_REPOSITORY_WRITE_LINK
			done
			unset a && unset temp && unset temp_tab
			sed -i 's/STEP_5=0/STEP_5=1/' $PROGRESS_FILE
		fi
		if [ $STEP_6 -eq 0 ]
		then
			echo "INFO: Installing Elasticsearch..."
			yum install -y $ELASTICSEARCH_PACKAGES_ALL
			sed -i 's/STEP_6=0/STEP_6=1/' $PROGRESS_FILE
		fi
		if [ $STEP_7 -eq 0 ]
		then
			echo "INFO: Activating automatic start-up for Elasticsearch..."
			temp_tab=( ONE TWO )
			for a in `seq 0 1`;
			do
				temp="ELASTICSEARCH_AUTOLOAD_CENTOS_${temp_tab[$a]}"
				command_autoload="$ELASTICSEARCH_AUTOLOAD_CENTOS_LINK $(eval echo \$$temp)"
				$command_autoload
			done
			unset a && unset temp && unset temp_tab && unset command_autoload
			sed -i 's/STEP_7=0/STEP_7=1/' $PROGRESS_FILE
		fi
		if [ $STEP_8 -eq 0 ]
		then
			echo "INFO: Installation of plugins (1/2)..."
			$ELASTICSEARCH_PLUGIN_ONE_ALL
			sed -i 's/STEP_8=0/STEP_8=1/' $PROGRESS_FILE
		fi
		if [ $STEP_9 -eq 0 ]
		then
			echo "INFO: Installation of plugins (2/2)..."
			$ELASTICSEARCH_PLUGIN_TWO_ALL
			sed -i 's/STEP_9=0/STEP_9=1/' $PROGRESS_FILE
		fi
		if [ $STEP_10 -eq 0 ]
		then
			echo "INFO: Configuring Elasticsearch..."
			sed -i "$ELASTICSEARCH_CLUSTERNAME_REPLACEMENT" $ELASTICSEARCH_CONFIG_LINK
			sed -i "$ELASTICSEARCH_BINDHOST_REPLACEMENT" $ELASTICSEARCH_CONFIG_LINK
			echo "INFO: Cluster.name: $cluster_name, host: 127.0.0.1"
			sed -i 's/STEP_10=0/STEP_10=1/' $PROGRESS_FILE
		fi
		echo "INFO: Starting Elasticsearch..."
		/etc/init.d/elasticsearch start
		echo "INFO: Installation of Elasticsearch is completed"

		echo "INFO: Step3: PHP"
		if [ $STEP_11 -eq 0 ]
		then
			echo "INFO: Installation of the PHP packages..."
			yum install -y $PHP_PACKAGES_CENTOS
			pecl install -f $PHP_PECL_PACKAGES
			echo "$PHP_CONFIG_WRITE" > $PHP_CONFIG_LINK_CENTOS
			sed -i 's/STEP_11=0/STEP_11=1/' $PROGRESS_FILE
		fi
		if [ $STEP_12 -eq 0 ]
		then
			echo "INFO: Configuring PHP..."
			sed -i "$PHP_CONFIG_TIMEZONE_REPLACEMENT_ALLDEB" $PHP_CONFIG_LINK_PHPINI_CENTOS
			sed -i 's/STEP_12=0/STEP_12=1/' $PROGRESS_FILE
		fi
		echo "INFO: Installation of PHP is completed"

		echo "INFO: Step4: Rubedo"
		if [ $STEP_13 -eq 0 ]
		then
			echo "INFO: Installation of Git..."
			yum install -y $GIT_PACKAGES_ALL
			sed -i 's/STEP_13=0/STEP_13=1/' $PROGRESS_FILE
		fi
		if [ $STEP_14 -eq 0 ]
		then
			echo "INFO: Cloning Rubedo..."
			git clone -b "$GIT_CLONE_VERSION" $GIT_CLONE_LINK
			sed -i 's/STEP_14=0/STEP_14=1/' $PROGRESS_FILE
		fi
		if [ $STEP_15 -eq 0 ]
		then
			echo "INFO: Configuring Apache..."
			temp_tab=( ONE TWO THREE FOUR FIVE SIX )
			for a in `seq 0 5`;
			do
				temp="APACHE_CONFIG_CENTOS_REPLACEMENT_${temp_tab[$a]}"
				sed -i "$(eval echo \$$temp)" $APACHE_CONFIG_CENTOS_REPLACEMENT_LINK
			done
			unset a && unset temp && unset temp_tab
			sed -i 's/STEP_15=0/STEP_15=1/' $PROGRESS_FILE
		fi
		if [ $STEP_16 -eq 0 ]
		then
			echo "INFO: Adding a new host..."
			sed -i "$APACHE_NEWHOST_REPLACEMENT_ALL" $APACHE_NEWHOST_LINK_ALL
			sed -i 's/STEP_16=0/STEP_16=1/' $PROGRESS_FILE
		fi
		if [ $STEP_17 -eq 0 ]
		then
			echo "INFO: Installing and preparing composer..."
			curl -sS $COMPOSER_LINK | php -- --install-dir=$COMPOSER_DESTINATION
			cd $COMPOSER_DESTINATION
   			php $COMPOSER_FILE config -g $COMPOSER_WEBSITEGIT "$TOKEN_GITHUB"
			cd $link_script
			sed -i 's/STEP_17=0/STEP_17=1/' $PROGRESS_FILE
		fi
		echo "INFO: Running composer..."
		cd $COMPOSER_DESTINATION
		$RUBEDO_INSTALL_SCRIPT
		cd $link_script
		if [ $STEP_18 -eq 0 ]
		then
			echo "INFO: Preparing the installation page..."
			temp_tab=( ONE TWO )
			for a in `seq 0 1`;
			do
				temp="INSTALL_REPLACEMENT_${temp_tab[$a]}"
				sed -i "$(eval echo \$$temp)" $INSTALL_LINK
			done
			unset a && unset temp && unset temp_tab
			sed -i 's/STEP_18=0/STEP_18=1/' $PROGRESS_FILE
			sed -i 's/STEP_19=0/STEP_19=1/' $PROGRESS_FILE
		fi
		echo "INFO: Starting Apache..."
		apachectl start
		echo "INFO: Installation of Rubedo is completed"

	;;
	*)
		echo "ERROR: This script cannot detect the type of distribution or it's not supported"
		echo "For more details: $DOCUMENTATION_SETUP_URL"
		exit 1
	;;
esac
echo "INFO: Rubedo is now installed, but not operational"
echo "INFO: Go to rubedo.local/install with a navigator to complete the installation"
echo "INFO: Thanks for using this agent"
