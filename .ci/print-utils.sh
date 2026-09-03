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
	repeat_string ' ' "$pad_r_len"
	printf '%s' "$string"
	repeat_string ' ' "$pad_l_len"
}
section() {
	text_color=6
	border_color=3
	echo
	on_github && echo "::group::$1"
	set_fg_color "$border_color"
	echo '/============================================================================\'
	set_fg_color "$border_color"
	printf '%s' "|"
	set_fg_color "$text_color"
	center "$1" 76
	set_fg_color "$border_color"
	printf '%s\n' "|"
	set_fg_color "$border_color"
	echo '\============================================================================/'
	set_fg_color 9
}
section_end() {
	text_color=6
	border_color=3
	echo
	set_fg_color "$border_color"
	printf '%s' '\================================+'
	set_fg_color "$text_color"
	printf '%s' 'END-SECTION'
	set_fg_color "$border_color"
	printf '%s\n' '+===============================/'
	set_fg_color 9
	on_github && echo "::endgroup::"
}
