#!/bin/sh

# Fetches the broken KDE plasma6-plasma-desktop package, fixes the unnecessary
# dependency on xf86-input-libinput, increments its revision by 10 repackages
# it and puts it in the directory specified by the first argument.
# The new package's path is printed to stdout.

set -eu

[ -n "$1" ] || (echo 'Destination directory not specified'>&2; exit 1)
[ -d "$1" ] || (echo 'Destination directory not found'>&2; exit 1)
[ -w "$1" ] || (echo 'Destination directory not writeable'>&2; exit 1)


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

retry_with_latest="true"
tmpdir=$(mktemp -d)
trap 'rm -fr "${tmpdir}"' EXIT INT TERM


fetchdir="${tmpdir}/fetch-dir"
repoconfdir="${tmpdir}/repo-conf-dir"
mkdir "${fetchdir}"
pkg fetch -qy -o "${fetchdir}" plasma6-plasma-desktop || {
	if [ "$retry_with_latest" = "true" ]
	then
		echo 'Failed to fetch the package.'\
			'Trying the FreeBSD latest repository...'>&2
		rm -fr "${fetchdir:?}/*"
		mkdir "${repoconfdir}"
		latest_repo_conf > "${repoconfdir}/FBSD_LATEST.conf"
		pkg -R "${repoconfdir}" fetch -qy\
			-r FBSD_LATEST -o "${fetchdir}" plasma6-plasma-desktop
		rm -fr "${repoconfdir}"
	else
		echo 'Failed to fetch the package.'>&2
		exit 1
	fi
}


if [ "$(find "${fetchdir}" -type f -exec printf '.' \; | wc -c)" -ne 1 ]
then
	echo 'Wrong number of fetched files.'>&2
	exit 1
fi

packagedir="${tmpdir}/pkg-dir"
mkdir "${packagedir}"
packagefile="$(find "${fetchdir}" -type f)"
tar -xzf "${packagefile}" -C "${packagedir}"
rm -fr "${fetchdir}"
rm -fr "${repoconfdir}"

awk 'BEGIN{RS="\0";FS="\0"}
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
	}' "${packagedir}/+MANIFEST" > "${packagedir}/+MANIFEST.tmp"
mv "${packagedir}/+MANIFEST.tmp" "${packagedir}/+MANIFEST"

pkg create -q -T auto -r "${packagedir}" -m "${packagedir}" -o "${tmpdir}"
rm -fr "${packagedir}"

outpkgfile="$(find "${tmpdir}" -type f)"
mv "${outpkgfile}" "$1/"
printf '%s\n' "${outpkgfile}"
exit 0
