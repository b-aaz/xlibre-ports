#!/bin/sh
[ -z  "${____leeppeel____dotted+x}" ] ||{ :;return; }
readonly ____leeppeel____dotted=1

. ./indirect.sh # let, get, islet, isvar, unlet ..

# LEEP (archaic spelling of leap)
# LEEPs into a new function stack.
# shellcheck disable=SC2120
leep() {
	[ "${#}" -eq 0 ] || exit
	[ "${____leeppeel____depth=0}" -ge 0 ] || exit
	____leeppeel____depth=$((____leeppeel____depth+1))
}
# PEEL
# PEELs off the current stack, optionally returns a code.
# shellcheck disable=SC2120
# $1: return code or return code holder's variable name.
peel() {
	[ $# -le 1 ] || exit
	[ "${____leeppeel____depth=0}" -gt 0 ] || exit
	:; ____leeppeel____ret=$? # Trues out the return value.

	if [ $# -eq 1 ]
	then 
		# In case our first argument is numeric, use it as the exit code.
		if { [ "${1}" -ge 0 ] && [ "${1}" -le 255 ]; } 2>/dev/null; then
			____leeppeel____ret=${1}
		else # If it is not numeric, try getting its value by indirection.
			get "____leeppeel____ret" "${1}" || exit
			: "${____leeppeel____ret:=$?}"
			[ "${____leeppeel____ret}" -ge 0   ] || exit
			[ "${____leeppeel____ret}" -le 255 ] || exit
		fi
	fi

	if islet "____leeppeel____${____leeppeel____depth}_var_list"
	then
		____leeppeel____old_ifs=${IFS}
		IFS=" "
		get "____leeppeel____tmp" \
			"____leeppeel____${____leeppeel____depth}_var_list" || exit
		: "${____leeppeel____tmp?}"


		for ____leeppeel____varname in ${____leeppeel____tmp}
		do
			____leeppeel____rawname="${____leeppeel____varname#[ru]'{'}"
			case "${____leeppeel____varname}" in
				'r{'*)


					get "${____leeppeel____rawname}" \
"____leeppeel____${____leeppeel____depth}_value_of_${____leeppeel____rawname}"\
						|| exit


					unlet \
"____leeppeel____${____leeppeel____depth}_value_of_${____leeppeel____rawname}"\
						|| exit


					;;
				'u{'*)
					unlet "${____leeppeel____rawname}" || exit
					;;
				*)
					false||exit
					;;
			esac
			unset ____leeppeel____rawname ____leeppeel____varname
		done


		unlet "____leeppeel____${____leeppeel____depth}_var_list" || exit
		IFS=${____leeppeel____old_ifs}
		unset ____leeppeel____old_ifs ____leeppeel____tmp
	fi

	____leeppeel____depth=$((____leeppeel____depth-1))

	[ "${____leeppeel____depth}" -ne 0 ] || unset ____leeppeel____depth

	eval "
		unset ____leeppeel____ret || true
		return '${____leeppeel____ret}'
	"
} 
# PRIVATE
# Defines a new PRIVATE variable.
# $1: variable name.
private(){
	[ $# -eq 1 ] || exit
	isvar "${1}" || exit

	get "____leeppeel____tmp" \
		"____leeppeel____${____leeppeel____depth}_var_list" || exit
	: "${____leeppeel____tmp?}"

	case "${____leeppeel____tmp}" in
		*' '[ru]"{${1} "*) true; return ;;
		*) ;;
	esac

	if islet "${1}";
	then
		let "____leeppeel____${____leeppeel____depth}_var_list" \
			"${____leeppeel____tmp} r{${1} " || exit

		get "____leeppeel____tmp" "${1}" || exit
		: "${____leeppeel____tmp?}"

		let "____leeppeel____${____leeppeel____depth}_value_of_${1}" \
			"${____leeppeel____tmp}" || exit
	else
		get "____leeppeel____tmp" \
		"____leeppeel____${____leeppeel____depth}_var_list" || exit
		: "${____leeppeel____tmp?}"

		let "____leeppeel____${____leeppeel____depth}_var_list" \
			"${____leeppeel____tmp} u{${1} " || exit
	fi
	unset ____leeppeel____tmp
	unlet "${1}" || exit
}
leep_depth(){
	[ $# -eq 1 ] || exit
	let "${1}" "${____leeppeel____depth}" || exit
}

# vi: ts=4 sw=4 tw=80 cc=80
