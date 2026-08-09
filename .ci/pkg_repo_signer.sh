#!/bin/sh
# shellcheck enable=deprecate-which
# shellcheck enable=add-default-case
# shellcheck enable=avoid-negated-conditions
# shellcheck enable=check-extra-masked-returns
# shellcheck enable=quotes-safe-variables
# shellcheck enable=require-variable-braces
# \/ For allowing the use of let. \/
# shellcheck disable=SC3039




(set -o pipefail 2>/dev/null)&&set -o pipefail
set -eu
sdir="$(dirname "${0}"||{ echo 'Script dir not found.'>&2;exit 1; };echo x)"
# shellcheck disable=SC1007
CDPATH= cd -- "${sdir%??}/shlib"||{ echo 'Can not cd to shlib dir.'>&2;exit 1; }

. ./indirect.sh # let, get, islet, isvar, unlet ..
. ./leeppeel.sh # leep, peel, private ...
. ./autotemp.sh # mktemp_autoclean ...
. ./basic_io.sh # out, puts, err ...
. ./cmdcheck.sh # cmd_exe_exists, cmd_exe_exists_die ...
. ./compress.sh # compress_pipe, decompress_pipe ...
. ./paxfuncs.sh # pax_at_dir ...

cd -- "${OLDPWD?}" ||{ echo 'Could not restore $PWD'>&2;exit 1; }


## Easy hash functions for signing.

# $1: file path to hash.
blake512sum_bin() { openssl dgst -blake2b512 -binary "${1}"; }
sha256sum_hex() { leep
	private 'file'	;file="${1}"
	private 'hex'
	private '_ret'
	hex="$(openssl dgst -sha256 -hex "${file}")" ||_ret=$?
	hex="${hex##* }"
	# It is important that this function does NOT add a newline at the end of
	# its input because pkg signs only the raw hex digits.
	out 1 "${hex}"
peel _ret; }

openssl_sanity_check(){ leep;while :;do
	private 'algo'	;algo="${1}"
	private 'curve'	;curve="${2}"
	private '_ret'

	cmd_exe_exists_die 'openssl'
	case "${algo}" in
		ecdsa)
			blake512sum_bin /dev/null >/dev/null 2>&1 ||{
				_ret=$?; err 'OpenSSL does not support blake2b512 hash.'; break
			}
			openssl ecparam -name "${curve}" >/dev/null 2>&1 ||{
				_ret=$?
				err "OpenSSL does not support the '${curve}' elliptic curve."
				break
			}
			;;
		rsa)
			sha256sum_hex /dev/null >/dev/null 2>&1 ||{
				_ret=$?; err 'OpenSSL does not support sha256sum hash.'; break
			}

			{ leep
				private 'key'
				mktemp_autoclean 'key' &&
					openssl genrsa > "${key=/dev/null}" &&
					openssl dgst -sign "${key}" /dev/null >/dev/null
			peel "${?}"; } ||{
				_ret=$?; err 'Failed to verify OpenSSL RSA support.'; break
			}
			;;
		*)
			err 'Key algorithm is not supported.'
			err 'Only ECDSA and RSA keys are supported.'
			false||_ret=$?;
			;;
	esac
break;done;peel _ret; }
posix_sanity_check(){
	cmd_exe_exists_die 'awk'
	cmd_exe_exists_die 'pax'
}


sign_file() { leep
	private 'algo'		;algo="${1}"
	private 'keyfile'	;keyfile="${2}"
	private 'file'		;file="${3}"
	private '_ret'

	case "${algo}" in
		ecdsa)
			# Header pkg uses only for ecdsa signatures, but RSA signatures
			# have no such headers... .
			# shellcheck disable=SC2016
			out 1 '$PKGSIGN:ecdsa$'
			openssl dgst -sha256 -sign "${keyfile}" -binary "${file}" ||_ret=$?
			;;
		rsa)
			openssl dgst -sha256 -sign "${keyfile}" -binary "${file}" ||_ret=$?
			# Yet another weirdness of pkg, for RSA keys, it adds a null
			# terminator byte at the end of the signature, and it has been kept
			# around for 'backwards compatibility reasons'.
			# It also means that this function's output should directly be
			# piped to a file and not stored in a variable cause the null byte
			# breaks them.
			printf '\0'
			;;
		*)
			err 'Key algorithm is not supported.'
			err 'Only ECDSA and RSA keys are supported.'
			false||_ret=$?
			;;
	esac
peel _ret; }

# $1: private key path.
generate_der_public_key(){ openssl pkey -outform der -pubout -in "${1}"; }
# $1: private key path.
generate_pem_public_key(){ openssl pkey -outform pem -pubout -in "${1}"; }
generate_pkg_public_key(){ leep
	private 'algo'		;algo="${1}"
	private 'keyfile'	;keyfile="${2}"
	private '_ret'

	# Yet another pkg weirdness. For a repository public key to be accepted by
	# pkg, the public key should be in exclusively DER format for ECDSA signed
	# repos, and in exclusively PEM for RSA signed repos.
	# Good luck finding that in the docs!
	case "${algo}" in
		rsa)
			generate_pem_public_key "${keyfile}" ||_ret=$?
			;;
		ecdsa)
			generate_der_public_key "${keyfile}" ||_ret=$?
			;;
		*)
			err 'Key algorithm is not supported.'
			err 'Only ECDSA and RSA keys are supported.'
			false||_ret=$?
			;;
	esac
peel _ret; }

key_type(){ leep;while :;do
	private 'algovar'	;algovar="${1}"
	private 'curvevar'	;curvevar="${2}"
	private 'keyfile'	;keyfile="${3}"
	private '_ret'

	# OpenSSL weirdness: -pubin does not mandate a public key as input, it also
	# accepts private keys.
	pem="$(openssl pkey -pubin -in "${keyfile}" -outform pem 2>/dev/null)" ||{
		_ret=$?; err 'Invalid key file.'; break
	}
	# But this form, ONLY accepts private keys.
	openssl pkey -in "${keyfile}" -check -noout > /dev/null 2>&1 ||{
		_ret=$?; err 'Public key given, while private key was expected.' break
	}

	# Extracts the algorithm and curve type from private key, and outputs them
	# on two lines.
	asn1="$(puts "${pem}" | openssl asn1parse |
	       	awk -F: '/: OBJECT/{s[length(s)]=$NF}END{print s[0]"\n"s[1]}'
	)"
	algo="$( puts "${asn1}" | awk 'NR==1{print}')"
	curve="$(puts "${asn1}" | awk 'NR==2{print}')"

	case "${algo}" in
		id-ecPublicKey)
			case "${curve}" in
				secp256k1)
					;;
				secp384r1)
					;;
				secp521r1)
					;;
				brainpoolP256r1)
					;;
				brainpoolP256t1)
					;;
				brainpoolP320r1)
					;;
				brainpoolP320t1)
					;;
				brainpoolP384r1)
					;;
				brainpoolP384t1)
					;;
				brainpoolP512r1)
					;;
				brainpoolP512t1)
					;;
				*)
					err "Key curve: '${curve}', is not supported."
					false||_ret=$?;break
					;;
			esac
			algo="ecdsa"
			;;
		rsaEncryption)
			algo="rsa"
			;;
		*)
			err 'Key algorithm is not supported.'
			err 'Only ECDSA and RSA keys are supported.'
			false||_ret=$?;break
			;;
	esac
	let "${algovar}" "${algo}" ||_ret=$?;break
	let "${curvevar}" "${curve}" ||_ret=$?;break
break;done;peel _ret; }

# $1: repository directory path.
repo_check(){
	[ -f "${1}/meta.conf" ] ||{
		err 'No meta.conf found, are you sure this is a pkg repo?'
		false||return
	}
	if ! [ -f "${1}/packagesite.pkg" ] && ! [ -f "${1}/data.pkg" ]
	then
		err 'Nither data.pkg, or packagesite.pkg found.'
		err 'Are you sure this is a pkg repo?'
		false||return
	fi
}

# $1: repository directory path.
get_pkg_archive_type(){
	case "$(
		cat "${1}/meta.conf" "${1}/meta" |
			sort |
			uniq |
			sed -n 's/^packing_format = "\([a-z]*\)";/\1/p'
	)" in
		'tzst')
			puts "zstd"
			;;
		'txz')
			puts "xz"
			;;
		'tbz')
			puts "bzip2"
			;;
		'tgz')
			puts "gzip"
			;;
		'tar')
			puts "raw"
			;;
		*)
			err "pkg archive type: '${1}', not recognized."
			false
			;;
	esac
}

insert_signature(){ leep; while :; do
	private 'algo'			;algo="${1}"
	private 'keyfile'		;keyfile="${2}"
	private 'archivetype'	;archivetype="${3}"
	private 'archive'		;archive="${4}"
	private 'tmpdir'		;tmpdir=""
	private '_ret'

	mktemp_autoclean 'tmpdir' -d ||{
		_ret=$?; err "Can not make temp directory."; break
	}

	<"${archive}" decompress_pipe "${archivetype}"|pax_at_dir "${tmpdir}" -r||{
		_ret=$?; err "Extraction of data archive: '${archive}' failed."; break
	}

	# shellcheck disable=SC2312
	# shellcheck disable=SC2319
	[ "$(find "${tmpdir}" -type f -exec printf '.' \; | wc -c)" -eq 1 ] ||{
		_ret=$?
		err "More than a single file found in archive: '${archive}'."
		err 'It has probably been signed before. Files found:'
		find "${tmpdir}" -type f 1>&2
		break
	}

	filepath="$(find "${tmpdir}" -type f -exec printf '%s.' {} \;)"
	filepath="${filepath%?}"

	# Yep, when generating a RSA signature, pkg hashes the datastore file with
	# sha256, BUT outputs it as a raw hex ASCII text string, and then signs
	# that hash with a sha256 digest RSA, but when signing with ECDSA it uses a
	# blake2b hash, this time in binary, and then signs it with sha256 digest
	# ecdsa. ... lovely.
	case "${algo}" in
		rsa)
			sha256sum_hex "${filepath}" > "${tmpdir}/hash.bin"
			;;
		ecdsa)
			blake512sum_bin "${filepath}" > "${tmpdir}/hash.bin"
			;;
		*)
			err 'Key algorithm is not supported.'
			err 'Only ECDSA and RSA keys are supported.'
			false||_ret=$?;break
			;;
	esac

	sign_file "${algo}" "${keyfile}" "${tmpdir}/hash.bin">"${tmpdir}/signature"

	rm "${tmpdir}/hash.bin"

	pax_at_dir "${tmpdir}" -w -s '@^\.$@@' -s '@^\.\/@@' . | 
		compress_pipe "${archivetype}" > "${archive}" ||{
			_ret=$?; err "Failed to repackage archive: '${archive}'."; break
		}

break;done;peel _ret; }

usage(){ err "usage: ${0} <privatekey-file>  <repo-file | repo-directory>"; }
usage_exit(){ usage; false||exit;}


main(){
	# Argument parsing and validation.
	[ "${#}" -eq 2 ] ||{ err 'This command takes two arguments:'; usage_exit; }

	[ -e "${1}" ] ||{ err "'${1}' file not found."; usage_exit; }
	[ -f "${1}" ] ||{ err "'${1}' is not a file."; usage_exit; }
	[ -r "${1}" ] ||{ err "'${1}' can not be read."; usage_exit; }
	[ -w "${1}" ] ||{ err "'${1}' can not be written to."; usage_exit; }
	keyfile="${1}"

	key_type 'algo' 'curve' "${keyfile}"

	[ -e "${2}" ] ||{ err "'${2}' not found."; usage_exit; }
	if [ -f "${2}" ]; then
		repofile="${2}"
	elif [ -d "${2}" ]; then
		repodir="${2}"
	else
		err "'${2}' is not a file or a directory."; usage_exit;
	fi
	[ -r "${2}" ] ||{ err "'${2}' can not be read."; usage_exit; }
	set --

	openssl_sanity_check "${algo}" "${curve}"
	posix_sanity_check

	[ -z "${repofile-}" ] ||{
		mktemp_autoclean 'repodir' -d ||{
			err "Can not make temp directory."
					exit 1
		}
		<"${repofile}" pax_at_dir "${repodir}" -r ||{
			err 'Extraction failed.'
					exit 1
		}
	}


	repo_check "${repodir}"

	archivetype="$(get_pkg_archive_type "${repodir}")"
	compress_sanity_check "${archivetype}"

	for datastore in packagesite filesite data
	do
		if [ -f "${repodir}/${datastore}.pkg" ]
		then
			insert_signature "${algo}" "${keyfile}" "${archivetype}"\
				"${repodir}/${datastore}.pkg" || exit
			err "Signed: '${datastore}'."
		fi
	done


	[ -z "${repofile-}" ] ||{
		pax_at_dir "${repodir}" -w . >"${repofile}.signed" 
			err 'Wrote the signed archive to:' "${repofile}.signed" 
	}

	[ -n "${repofile-}" ] &&
		pubkeyfile="${repofile}.public-key" ||
		pubkeyfile="${repodir}/public-key" 

	generate_pkg_public_key "${algo}" "${keyfile}" >"${pubkeyfile}"
	err "Wrote repository's public key, in a pkg compatible format to:"\
		"'${pubkeyfile}'."
}




main "$@"

# vi: ts=4 sw=4 tw=80 cc=80
