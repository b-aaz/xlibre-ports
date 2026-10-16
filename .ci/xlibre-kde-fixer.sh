#!/bin/sh
# shellcheck enable=deprecate-which
# shellcheck enable=add-default-case
# shellcheck enable=avoid-negated-conditions
# shellcheck enable=check-extra-masked-returns
# shellcheck enable=quotes-safe-variables
# shellcheck enable=require-variable-braces

# Fetches the broken KDE plasma6-plasma-desktop package, fixes the unnecessary
# dependency on xf86-input-libinput, increments its revision by 10, then
# repackages it and puts it in the directory specified by the first argument.
# The new package's path is printed to stdout.

set -eu
sdir="$(dirname "${0}"||{ echo 'Script dir not found.'>&2;exit 1; };echo x)"
# shellcheck disable=SC1007
CDPATH= cd -- "${sdir%??}/shlib"||{ echo 'Can not cd to shlib dir.'>&2;exit 1; }

. basic_io.sh # out puts err ...
. autotemp.sh # mktemp_autoclean ...
. cmdcheck.sh # cmd_exe_exists, cmd_exe_exists_die ...
. compress.sh # decompress_pipe, decompress_file_auto ...
. paxfuncs.sh # pax_at_dir ...



cd -- "${OLDPWD?}" ||{ echo 'Could not restore $PWD'>&2;exit 1; }


latest_repo_conf (){
	cat << 'EOF'
FBSD_LATEST: {
  url: "pkg+https://pkg.FreeBSD.org/${ABI}/latest",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
EOF
}

sanity_check() {
	cmd_exe_exists_die 'pkg'
	cmd_exe_exists_die 'pax'
	cmd_exe_exists_die 'awk'
}

usage(){ err "usage: ${0} <output-directory>"; }
usage_exit(){ usage; false||exit;}

patch_manifest(){
	awk '
		BEGIN{
			RS="a-very|improbablestring";
			FS="a-very|improbablestring"
		}
		{
			# Incrementing the revision number.

			match($0,"\"version\"[[:space:]]*:" \
			"[[:space:]]*\"[[:digit:]._]*\"")

			before=substr($0,1,RSTART-1)
			matched=substr($0,RSTART,RLENGTH-1)
			after=substr($0,RSTART+RLENGTH)

			match(matched,"[[:digit:]._]*$")
			version=substr(matched,RSTART,RLENGTH)
			if (split(version,arr,"_") == 2)
			{
				revision=arr[2]
			}
			else
			{
				revision=0
			}
			revision+=10;
			res=before "\"version\":\"" arr[1] "_" revision "\"" after;
			$0=res;

			# Removing the xf86-input-libinput dependency.

			gsub(",[[:space:]]*\"xf86-input-libinput\"[[:space:]]*:" \
			"[[:space:]]*{[[:space:]]*\"origin\"[[:space:]]*:" \
			"[[:space:]]*\"x11-drivers/xf86-input-libinput\"[[:space:]]*," \
			"[[:space:]]*\"version\"[[:space:]]*:" \
			"[[:space:]]*\"[[:digit:]._]*\"[[:space:]]*}","");

			# Just like the above pattern, but with revesed commas, in the
			# rare case with get this dependency as the first property.
			gsub("[[:space:]]*\"xf86-input-libinput\"[[:space:]]*:" \
			"[[:space:]]*{[[:space:]]*\"origin\"[[:space:]]*:" \
			"[[:space:]]*\"x11-drivers/xf86-input-libinput\"[[:space:]]*," \
			"[[:space:]]*\"version\"[[:space:]]*:" \
			"[[:space:]]*\"[[:digit:]._]*\"[[:space:]]*},","");

			print $0
		}
	'
}

main(){
	[ "${#}" -eq 1 ] ||{ err 'This command takes one argument:'; usage_exit; }
	[ -e "${1}" ] || { err "'${1}' not found."; usage_exit; }
	[ -d "${1}" ] || { err "'${1}' is not a directory."; usage_exit; }
	[ -w "${1}" ] || { err "'${1}' can not be written ot."; usage_exit; }
	outdir="${1}"
	set --

	sanity_check

	mktemp_autoclean 'tmpdir' -d
	retry_with_latest="true"
	fetchdir="${tmpdir:?}/fetch-dir"
	repoconfdir="${tmpdir}/repo-conf-dir"
	mkdir "${fetchdir}"
	pkg fetch -qy -o "${fetchdir}" plasma6-plasma-desktop || {
		if [ "${retry_with_latest}" = "true" ]
		then
			err 'Failed to fetch the package.'
			err 'Trying the FreeBSD latest repository...'
			rm -fr "${fetchdir:?}/*"
			mkdir "${repoconfdir}"
			latest_repo_conf > "${repoconfdir}/FBSD_LATEST.conf"
			pkg -R "${repoconfdir}" fetch -qy -r FBSD_LATEST -o "${fetchdir}"\
				plasma6-plasma-desktop
			rm -fr "${repoconfdir}"
		else
			err 'Failed to fetch the package.'
			false||exit
		fi
	}


	# shellcheck disable=SC2312
	[ "$(find "${fetchdir}" -type f -exec printf '.' \; | wc -c)" -eq 1 ] ||{
		err 'Wrong number of fetched files, expected one. Fetched files:'
			find "${fetchdir}" -type f 1>&2
			false||exit
	}
	packagefile="$(find "${fetchdir}" -type f  -exec printf '%s.' {} \;)"
	packagefile="${packagefile%?}"

	packagedir="${tmpdir}/pkg-dir"
	mkdir "${packagedir}"
	decompress_file_auto "${packagefile}"|pax_at_dir "${packagedir}" -r -s\
		'@^/*@@'
	rm -fr "${fetchdir}"
	rm -fr "${repoconfdir}"

	patch_manifest < "${packagedir}/+MANIFEST" > "${packagedir}/+MANIFEST.tmp"
	mv "${packagedir}/+MANIFEST.tmp" "${packagedir}/+MANIFEST"

	pkg create -q -T auto -r "${packagedir}" -m "${packagedir}" -o "${tmpdir}"
	rm -fr "${packagedir}"

	outpkgfile="$(find "${tmpdir}" -type f  -exec printf '%s.' {} \;)"
	outpkgfile="$(find "${tmpdir}" -type f)"
	mv "${outpkgfile}" "${outdir}/"
	puts "${outdir}/${outpkgfile##*/}"
}




main "$@"

# vi: ts=4 sw=4 tw=80 cc=80
