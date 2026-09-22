#!/bin/sh

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
	repeat_string "$3" "$pad_r_len"
	printf '%s' "$string"
	repeat_string "$3" "$pad_l_len"
}
section() {
	text_color=6
	border_color=3
	export SECTION_NAME="$1"
	export SECTION_START="$(awk 'BEGIN{srand(); print srand()}')"
	echo; on_github && echo "::group::${SECTION_NAME}"; echo
	set_fg_color "$border_color"
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
}
section_end() {
	SECTION_END="$(awk 'BEGIN{srand(); print srand()}')"
	SECTION_TIME="$((SECTION_END-SECTION_START))"
	text_color=6
	border_color=3
	echo
	set_fg_color "$border_color"
	printf '%s' '\'
	set_fg_color "$text_color"
	center "+END ${SECTION_NAME:-${1:-SECTION}} (${SECTION_TIME}s)+" 74 '='
	set_fg_color "$border_color"
	printf '%s\n' '/'
	set_fg_color 9
	echo; on_github && echo "::endgroup::"; echo
}
