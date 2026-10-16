#!/bin/sh
[ -z  "${____exit_cmd____dotted+x}" ] ||{ :;return; }
readonly ____exit_cmd____dotted=1

. indirect.sh # let, get, islet, isvar, unlet ..

# Adds a command to the exit command queue.
# Automagically adds the trap too.
# ...: command line.
add_exit_cmd(){
	case "$(printf '\n')$(trap)" in
		*"$(printf '\n')trap -- exit_runner "*)
			[ "${____exit_cmd____count:=0}" -ge 0 ] || ____exit_cmd____count=0
			;;
		*)
			# shellcheck disable=SC3049
			trap -- 'exit_runner' EXIT INT TERM HUP
			____exit_cmd____count=0
			;;
	esac
	let "____exit_cmd____${____exit_cmd____count}" "${*}"
	____exit_cmd____count="$((____exit_cmd____count+1))"
}

# Runs the exit command queue, should be added as a trap for appropriate
# signals for the shell.
exit_runner(){
	if [ -n "${____exit_cmd____count-}" ]
	then	
		____exit_cmd____i=0
		while [ "${____exit_cmd____i}" -lt "${____exit_cmd____count}" ]
		do
			get '____exit_cmd____cmd' "____exit_cmd____${____exit_cmd____i}"
			unlet "____exit_cmd____${____exit_cmd____i}"
			# shellcheck disable=SC2154
			eval "${____exit_cmd____cmd}"
			____exit_cmd____i="$((____exit_cmd____i+1))"
		done
		unset ____exit_cmd____i ____exit_cmd____cmd
	fi
}

# vi: ts=4 sw=4 tw=80 cc=80
