#!/bin/sh
[ -z  "${____compress____dotted+x}" ] ||{ :;return; }
readonly ____compress____dotted=1

. basic_io.sh # out, puts, err ...
. cmdcheck.sh # cmd_exe_exists, cmd_exe_exists_die ...

# $1: compression format.
compression_sanity_check(){
	case "${1}" in
		'zstd')	cmd_exe_exists_die 'zstd' ;;
		'gzip')	cmd_exe_exists_die 'gzip' ;;
		'bzip2')cmd_exe_exists_die 'bzip2' ;;
		'lz4')	cmd_exe_exists_die 'lz4' ;;
		'xz')	cmd_exe_exists_die 'xz' ;;
		'lzma')	cmd_exe_exists_die 'lzma' ;;
		'raw')	;;
		*)
			cmd_exe_exists_die 'zstd'
			cmd_exe_exists_die 'gzip'
			cmd_exe_exists_die 'bzip2'
			cmd_exe_exists_die 'lz4'
			cmd_exe_exists_die 'xz'
			cmd_exe_exists_die 'lzma'
			;;
	esac
}

# $1: compression format.
compress_pipe(){
	case "${1}" in
		'zstd')	zstd -zc ;;
		'gzip')	gzip -c ;;
		'bzip2')bzip2 -zc ;;
		'lz4')	lz4 -zc ;;
		'xz')	xz -zc ;;
		'lzma')	xz -zc ;;
		'raw')	cat ;;
		*)
			err "Archive type: '${1}', not recognized."
			false||return
			;;
	esac
}

# $1: compression format.
decompress_pipe(){
	case "${1}" in
		'zstd')	zstd -dc ;;
		'gzip')	gzip -dc ;;
		'bzip2')bzip2 -dc ;;
		'lz4')	lz4 -dc ;;
		'xz')	xz -dc ;;
		'lzma')	xz -dc ;;
		'raw')	cat ;;
		*)
			err "Archive type: '${1}', not recognized."
			false||return
			;;
	esac
}

#unod(){
#	for ____compress____i in "$@"
#	do
#		printf "\\${____compress____i}"
#	done
#}
#decompress_pipe_auto(){
#	set -- "$(dd bs=1 count=8 status=none 2>/dev/null | od -An -t o1)"
#	set -- "${1}" "$(unod $1 | od -An -t x1 | tr -d ' ')"
#	case "${2}" in
#		'28b52ffd'*)
#			{ unod ${1}; cat; } | zstd -dc
#			;;
#		'1f8b'*)
#			{ unod ${1}; cat; } | gzip -dc
#			;;
#		'425a68'*)
#			{ unod ${1}; cat; } | bzip2 -dc
#			;;
#		'04224d18'*)
#			{ unod ${1}; cat; } | lz4 -dc
#			;;
#		'fd377a585a00'*)
#			{ unod ${1}; cat; } | xz -dc
#			;;
#		'5d00'*)
#			{ unod ${1}; cat; } | lzma -dc
#			;;
#		*)
#			err "Archive type not recognized, defaulting to raw!"
#			unod ${1}; cat
#			;;
#	esac
#}

# $1: file path.
decompress_file_auto(){
	set -- "${1}" "$(od -N 8 -An -t x1 -- "${1}" | tr -d ' ' )"
	case "${2}" in
		'28b52ffd'*)	cmd_exe_exists_die 'zstd';	zstd -dc -- "${1}" ;;
		'1f8b'*)		cmd_exe_exists_die 'gzip';	gzip -dc -- "${1}" ;;
		'425a68'*)		cmd_exe_exists_die 'bzip2';	bzip2 -dc -- "${1}" ;;
		'04224d18'*)	cmd_exe_exists_die 'lz4';	lz4 -dc -- "${1}" ;;
		'fd377a585a00'*)cmd_exe_exists_die 'xz';	xz -dc -- "${1}" ;;
		'5d00'*)		cmd_exe_exists_die 'lzma';	lzma -dc -- "${1}" ;;
		*)
			err "Archive type not recognized, defaulting to raw!"
			cat -- "${1}"
			;;
	esac
}

# vi: ts=4 sw=4 tw=80 cc=80
