#!/bin/bash

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