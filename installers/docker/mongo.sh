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

[[ -d ${MONGODB_PATH} ]] || mkdir ${MONGODB_PATH}

RANDOM_ID=$(generate_random_string)
MONGO_NAME=$(req_input "Enter container name (default "${RANDOM_ID}"): " ${RANDOM_ID})

if ! [ ${DOCKER_NAME} ]; then
	DOCKER_NAME=mongodb_${MONGO_NAME}
fi

echo ${DOCKER_NAME}

# Set Locale
setLocale "en_US.UTF-8"

#Install Docker
installDocker

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

if [[ $SWAP_MEM =~ ^[0-9]+$ ]]; then
	createSwap $SWAP_MEM
else
	echo "Please enter an integer for SWAP Memory"
fi

if [[ $PORT =~ ^[0-9]+$ ]]; then
	createMongoContainer
else
	echo "Please pass a valid Port to be configured"
fi
