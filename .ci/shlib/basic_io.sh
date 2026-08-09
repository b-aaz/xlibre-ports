#!/bin/sh
[ -z  "${____basic_io____dotted+x}" ] ||{ :;return; }
readonly ____basic_io____dotted=1

# Some shorthand I/O functions.
# $1: file descriptor.
# ...: string.
out() { { shift; printf '%s' "${*}"; }>&"${1}"; }
# ...: string.
puts() { out 1 "${*}
"; } # Important newline.
# ...: string.
err() { out 2 "${*}
"; } # Important newline.

# vi: ts=4 sw=4 tw=80 cc=80
