#!/bin/sh
[ -z  "${____indirect____dotted+x}" ] ||{ :;return; }
readonly ____indirect____dotted=1

# Checks if the given string is a valid variable name or not.
# $1: var name.
isvar(){
	# This case logic helps really speed up the test, compared to regex+expr.
	case "${1}" in
		'')
			false||return
			;;
		[0123456789]*)
			false||return
			;;
		# Explicit char list to avoid weirdness with locals and char ranges
		# (i.e. [a-z]) in some shells.
		*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]*)
			false||return
			;;
		*)
			:;return
			;;
	esac
	false
}

## Some indirection primitives.

# Sets a given variable based on its name to a value, indirectly.
# $1: var name.
# $2: var value.
let(){
	[ $# -eq 2 ] || return
	isvar "${1}" || return
	eval "$1=\${2}"
}
# Sets one variable to another's value based on their names, indirectly.
# $1: destination variable name.
# $2: source variable name.
get(){
	[ $# -eq 2 ] || return
	isvar "${1}" || return
	isvar "${2}" || return
	eval "$1=\${$2-}"
}
# Unsets the given variable based on its name, indirectly.
# $1: variable name.
unlet(){
	[ $# -eq 1 ] || return
	isvar "${1}" || return
	eval "unset $1"
}
# Checks if the given variable is set based on its name, indirectly.
# $1: variable name.
islet(){
	[ $# -eq 1 ] || return
	isvar "${1}" || return
	eval "[ -n \"\${${1}+x}\" ]"
}

# vi: ts=4 sw=4 tw=80 cc=80
