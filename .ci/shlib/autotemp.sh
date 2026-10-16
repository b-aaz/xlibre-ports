#!/bin/sh
[ -z  "${____autotemp____dotted+x}" ] ||{ :;return; }
readonly ____autotemp____dotted=1

. leeppeel.sh # let, get, islet, isvar, unlet ..
. indirect.sh # let, get, islet, isvar, unlet ..
. exit_cmd.sh # add_exit_cmd, exit_runner

# Safely quotes strings for reevals by the shell. !No outer qoutes are added!
quote_escape(){ sed "s#'#\\\'#g"; }

# mktemp that automagically cleans after itself, how awesome!
# The temp file's path gets stored in the variable named in the first argument.
mktemp_autoclean(){ leep;while :;do
	private 'pathvar'	;pathvar="${1}"
	private 'path'
	private '_ret'
	shift
	
	path=$(mktemp "${@}";printf 'x') ||{ _ret=$?;break; }
	path=${path%??}
	let "${pathvar}" "${path}" ||{ _ret=$?;break; }
	path="$(out 1 "${path}" | quote_escape; printf 'x')"
	path=${path%?}
	add_exit_cmd "rm -fr -- '${path}'" ||_ret=$?
break;done;peel _ret; }

# vi: ts=4 sw=4 tw=80 cc=80
