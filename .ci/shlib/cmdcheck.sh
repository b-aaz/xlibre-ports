#!/bin/sh
[ -z  "${____cmdcheck____dotted+x}" ] ||{ :;return; }
readonly ____cmdcheck____dotted=1

# Check if a command exists and is actually an executable.
# shellcheck disable=SC2312
# $1: the command name.
cmd_exe_exists(){ [ -x "$(command -v "${1}")" ]; }

# Same as above but it just exits if command isn't found.
# $1: the command name.
cmd_exe_exists_die(){
	cmd_exe_exists "${1}" ||{
		err 'Required binary `'"${1}"'` not found, exiting.'
		false||exit
	}
}

# vi: ts=4 sw=4 tw=80 cc=80
