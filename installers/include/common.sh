#!/bin/bash

# Fixing Locale
function setLocale() {
	if ! locale | grep LANGUAGE > "${1}"; then
		sudo apt-add-repository -y ppa:git-core/ppa
		sudo apt-get -qq update
		echo "Fixing locale"
		sudo locale-gen ${1}
		export LANGUAGE=${1}
		export LC_ALL=${1}
		sudo dpkg-reconfigure -p critical locales
		echo -e "LANGUAGE=\"${1}\"\nLC_ALL=\"${1}\"\n" | sudo bash -c 'tee >> /etc/environment'
	else
		echo "Locale already set"
	fi
}


#Get Inputs
function get_input() {
	if ! [[ -z "$1" ]]; then
		echo "$1"
	else
		read -p "$2" _temp
		if [ "$_temp" != '' ]; then
			echo "$_temp"
		else
			echo "$3"
		fi
	fi
}

# Required Input
function req_input() {
	_temp=""
	while ! [ $_temp ]
	do
		read -p "$1" _temp
		if [ "${_temp}" == "" -a "${2}" ]; then
			echo ${2}
			break
		fi
	done

	if [ "${_temp}" ]; then
		echo $_temp
	fi
}

#Generate Random String
function generate_random_string() {
	echo $(xxd -l16 -ps /dev/urandom)
}

function in_array() {
    for item in "${@:2}"
    do
        [[ "$item" = "$1" ]] && return 0;
    done;
    return 1;
}

# Create Swap Memory
function createSwap() {
	if ! [[ ${1} =~ ^[0-9]+$ ]]; then
		echo "Please enter an integer for SWAP Memory"
	else
		if free | awk '/^Swap:/ {exit !$2}'; then
			echo "Have swap"
		else
			sudo fallocate -l ${1}G ~/swapfile
			sudo chmod 600 ~/swapfile
			sudo mkswap ~/swapfile
			sudo swapon ~/swapfile
			sudo cp /etc/fstab /etc/fstab.bak
			echo '~/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
		fi
	fi
}

# Installing Docker
function installDocker() {
	if ! command -v docker > /dev/null; then
		echo "Installing Docker"
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
		sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
		sudo apt-get -qq update
		apt-cache policy docker-ce
		sudo apt-get -qq install -y docker-ce
		sudo usermod -a -G docker $USER
	else
		echo "Docker already Installed"
	fi
}

# Installing Docker Compose
function installDockerCompose() {
	if ! command -v docker-compose > /dev/null; then
		echo "Installing Docker Compose"
		sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
		sudo chmod +x /usr/local/bin/docker-compose
	else
		echo "Docker Composer already Installed"
	fi
}
