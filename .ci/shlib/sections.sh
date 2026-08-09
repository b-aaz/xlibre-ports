#!/bin/sh

unix_time(){ awk 'BEGIN{srand(); print srand()}'; }
on_github() {
	[ "${GITHUB_ACTIONS}" = "true" ]
}
set_fg_color(){
	[ "$1" -le 9 ] && [ "$1" -gt 0 ] && printf "%s" "[0;3$1m"
	[ "$1" -eq 9 ] && printf "%s" "[0m"
	true
}
repeat_string() {
	char="$1"
	count="$2"
	while [ "$count" -gt 0 ]
	do
		printf '%s' "$char"
		count=$(( count - 1 ))
	done
}
center() {
	string="$1"
	string_len=${#string}
	pad_len="$2"
	pad_r_len=$(( (pad_len - string_len)/2 + (pad_len - string_len)%2 ))
	pad_l_len=$(( (pad_len - string_len)/2 ))
	[ -n "${4:-}" ] && set_fg_color "$4"
	repeat_string "${3:-' '}" "$pad_r_len"
	[ -n "${5:-}" ] && set_fg_color "$5"
	printf '%s' "$string"
	[ -n "${4:-}" ] && set_fg_color "$4"
	repeat_string "${3:-' '}" "$pad_l_len"
}
section() {
	[ -n "${-%%*x*}" ] && no_dbg="true" || no_dbg="false"
	set +x

	text_color=6
	border_color=3
	SECTION_NAME="$1"
	SECTION_START="$(unix_time)"
	export SECTION_NAME SECTION_START
	echo; on_github && echo "::group::${SECTION_NAME}"; echo
	set_fg_color "$border_color"
	# shellcheck disable=1003
	echo '/============================================================================\'
	set_fg_color "$border_color"
	printf '%s' "|"
	set_fg_color "$text_color"
	center "${SECTION_NAME}" 76 ' '
	set_fg_color "$border_color"
	printf '%s\n' "|"
	set_fg_color "$border_color"
	echo '\============================================================================/'
	set_fg_color 9

	"${no_dbg}" || set -x
}
section_end() {
	[ -n "${-%%*x*}" ] && no_dbg="true" || no_dbg="false"
	set +x

	SECTION_END="$(unix_time)"
	SECTION_TIME="$((SECTION_END-SECTION_START))"
	text_color=6
	border_color=3
	echo
	set_fg_color "$border_color"
	# shellcheck disable=1003
	printf '%s' '\'
	set_fg_color "$text_color"
	end_string="+END ${SECTION_NAME:-${1:-SECTION}} (${SECTION_TIME}s)+" 
	center "$end_string" 74 '=' "$border_color" "$text_color"
	set_fg_color "$border_color"
	printf '%s\n' '/'
	set_fg_color 9
	echo; on_github && echo "::endgroup::"; echo
	[ -n "${-%%*x*}" ] && dbg="true" || dbg="false"

	"${no_dbg}" || set -x
}
