#!/bin/bash

INSTALLERS_DIR=$(dirname ${0})/installers
INCLUDE_DIR=./include

if [ -d ${INSTALLERS_DIR}/include ]; then
	INCLUDE_DIR=${INSTALLERS_DIR}/include
fi

[[ -d ${INCLUDE_DIR} ]] || mkdir ${INCLUDE_DIR}

if ! [ -e ${INCLUDE_DIR}/common.sh ]; then
	curl -o ${INCLUDE_DIR}/common.sh 'https://raw.githubusercontent.com/thoughtchimp/installer/master/common.sh'
fi

source ${INCLUDE_DIR}/common.sh

AVAILABLE_DOCKER_INSTALLERS=(
    "mongo"
)

AVAILABLE_INSTALLERS=(
    "mongo"
)

MODE="direct"

# Parsing commandline args
while getopts "h?i:d" opt; do
    case "${opt}" in
        h|\?)
        printHelp
        exit 0
        ;;
        i)  INSTALLER=$OPTARG
        ;;
        d)  MODE="docker"
        ;;
    esac
done

if [ "${MODE}" == "" ]; then
    MODE="direct"
fi

if [ "${INSTALLER}" == "" ]; then
    echo "You need to pass utility name in order to install that, for exp: ./installer.sh -i mongo" && exit 1;
fi

if [ "${MODE}" == "direct" ]; then
    if ! $(in_array "${INSTALLER}" "${AVAILABLE_INSTALLERS[@]}"); then
        echo "'${INSTALLER}' is not supported for ${MODE}!" && exit 1;
    fi
fi

if [ "${MODE}" == "docker" ]; then
    if ! $(in_array "${INSTALLER}" "${AVAILABLE_DOCKER_INSTALLERS[@]}"); then
        echo "'${INSTALLER}' is not supported for ${MODE}!" && exit 1;
    fi
fi

[[ -d ${INSTALLERS_DIR}/${MODE} ]] || mkdir -p ${INSTALLERS_DIR}/${MODE}

if [ -e ${INSTALLERS_DIR}/${MODE}/${INSTALLER}.sh ]; then
    # source ${INSTALLERS_DIR}/${MODE}/${INSTALLER}.sh
    echo "Installer file exist!"
else
    echo "Has to download the installer file from repository"
fi
