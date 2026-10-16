#!/bin/sh
[ -z  "${____paxfuncs____dotted+x}" ] ||{ :;return; }
readonly ____paxfuncs____dotted=1


# Runs pax in the given directory.
# Does not run in a sub-shell, because in the average use case of pax it is ran
# in a pipeline, which is an implicit sub-shell. But a cd back to OLDPWD is
# there as the second to last command for safety in some weird shells' pipeline
# optimization, and in case this function was ran outside of a pipeline.
# $1: directory to chdir to.
pax_at_dir(){
	CDPATH='' cd -- "${1:?}" || exit
	shift
	pax "${@}"
	# Hackish way of preventing $? from getting overwritten.
	eval 'CDPATH="" cd -- "${OLDPWD:?}" || exit;' "return \"$?\";"
}

# vi: ts=4 sw=4 tw=80 cc=80
