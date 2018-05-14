#!/bin/bash

INSTALLERS_DIR=$(dirname $(dirname ${0}))
INCLUDE_DIR=./include

if [ -d ${INSTALLERS_DIR}/include ]; then
	INCLUDE_DIR=${INSTALLERS_DIR}/include
fi

[[ -d ${INCLUDE_DIR} ]] || mkdir ${INCLUDE_DIR}

if ! [ -e ${INCLUDE_DIR}/common.sh ]; then
	curl -o ${INCLUDE_DIR}/common.sh 'https://raw.githubusercontent.com/thoughtchimp/installer/master/common.sh'
fi

source ${INCLUDE_DIR}/common.sh

: ${PORT:=27017}
: ${MONGODB_PATH:=~/mongo-data}
: ${SWAP_MEM:=1}

[[ -d ${MONGODB_PATH} ]] || mkdir ${MONGODB_PATH}

RANDOM_ID=$(generate_random_string)
MONGO_NAME=$(req_input "Enter container name (default "${RANDOM_ID}"): " ${RANDOM_ID})

if ! [ ${DOCKER_NAME} ]; then
	DOCKER_NAME=mongodb_${MONGO_NAME}
fi

echo ${DOCKER_NAME}

# Fixing Locale
if ! locale | grep LANGUAGE > "en_US.UTF-8"; then
	sudo apt-add-repository -y ppa:git-core/ppa
	sudo apt-get -qq update
	echo "Fixing locale"
	sudo locale-gen en_US.UTF-8
	export LANGUAGE="en_US.UTF-8"
	export LC_ALL="en_US.UTF-8"
	sudo dpkg-reconfigure -p critical locales
	echo -e 'LANGUAGE="en_US.UTF-8"\nLC_ALL="en_US.UTF-8"\n' | sudo bash -c 'tee >> /etc/environment'
else
	echo "Locale already set"
fi

# Checking Docker Compose
if ! command -v docker-compose > /dev/null; then
	echo "Installing Docker Compose"
	sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
else
	echo "Docker Composer already Installed"
fi

# Checking Docker
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

# Create Swap Memory
function createSwap() {
  if free | awk '/^Swap:/ {exit !$2}'; then
      echo "Have swap"
  else
      sudo fallocate -l ${SWAP_MEM}G ~/swapfile
      sudo chmod 600 ~/swapfile
      sudo mkswap ~/swapfile
      sudo swapon ~/swapfile
      sudo cp /etc/fstab /etc/fstab.bak
      echo '~/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  fi
}

# Create Database MongoDB
function createDatabase() {
	db_name=$(req_input "Enter Database Name: ")
	db_username=$(req_input "Enter DB's username: ")
	db_password=$(req_input "Enter DB's password: ")
	sudo docker exec -i $DOCKER_NAME mongo -u $1 -p $2 --authenticationDatabase admin <<-EOF
	use $db_name;
  	db.createUser({ user: "$db_username", pwd: "$db_password", roles: [{db:"$db_name", role:"readWrite"}] });
	EOF
}

# MongoDB Initialization
function createMongoContainer() {
	sudo docker run -d --name $DOCKER_NAME -p $PORT:27017 -v ${MONGODB_PATH}/${MONGO_NAME}:/data/db mongo --auth
	admin_username=$(get_input "" "Enter admin's username (default admin): " "admin")
	admin_password=$(get_input "" "Enter admin's password (default adminPass): " "adminPass")
	sudo docker exec -i $DOCKER_NAME mongo admin <<-EOF
	db.createUser({ user: "$admin_username", pwd: "$admin_password", roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] });
	EOF
	
	if [ "$DATABASE" == "true" ]; then
		createDatabase $admin_username $admin_password
  	fi
}

# Parsing commandline args
while getopts "s:p:d" opt; do
    case "${opt}" in
        s)  SWAP_MEM=$OPTARG
        ;;
        p)  PORT=$OPTARG
        ;;
        d)  DATABASE="true"
        ;;
    esac
done

if [[ $SWAPMEM =~ ^[0-9]+$ ]]; then
	createSwap
else
	echo "Please pass a valid Port to be configured"
fi

if [[ $PORT =~ ^[0-9]+$ ]]; then
	createMongoContainer
else
	echo "Please pass a valid Port to be configured"
fi
