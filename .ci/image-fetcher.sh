#!/bin/sh
log() {
	echo "[$(date)] $*"
}
dfbsd_fetch() {
	set -e
	VM_RUNNER_ARCH="x86_64" # This is the only arch supported by DFBSD.
	arch="${VM_RUNNER_ARCH}"
	url="https://mirror-master.dragonflybsd.org/iso-images/"
	fn="dfly-${arch}-${ver}_REL.img.bz2"
	furl="${url}${fn}"

	hashalgo="md5"
	hashf="${hashalgo}.txt"
	hurl="${url}${hashf}"

	log "Starting image download"
	start="$(awk 'BEGIN{srand(); print srand()}')"
	curl --fail-with-body -s -Z -L -C - -O "$furl"
	end="$(awk 'BEGIN{srand(); print srand()}')"
	download_time="$((end-start))"
	log "Image downloaded"

	log "Starting hash download"
	curl --fail-with-body -s "$hurl" -o hashs.txt 
       	log "Hash downloaded"
	img_hash="$("${hashalgo}sum" --tag "${fn}")"
	img_size="$(wc -c < "${fn}" | cut -f1)"
	grep -qF "$img_hash" hashs.txt || (echo "$hash_error" && exit 1)
	rm -f hashs.txt
	log "Starting image extraction"
	bzip2 -dkc "${fn}" > "vm-img"
	rm -f "${fn}"
	log "Image extracted"
	set +e

	# shellcheck disable=SC2016
	if [ -n "$1" ]
	then
		{
			printf '| **VM Image URL** | %s |\n' "${furl}"
			printf '| **VM Image hash (%s)** | `%s` |\n' \
				"${hashalgo}" "${img_hash}"
			printf '| **VM Image fetch time** | %ss |\n' \
				"${download_time}"
			printf '| **VM Image raw size** | %sb |\n' "${img_size}"
		} >> "${1}" 
	fi
}
fbsd_fetch() {
	set -e
	url="https://download.freebsd.org/releases/VM-IMAGES/${ver}-RELEASE/${arch}/Latest/"
	fn="FreeBSD-${ver}-RELEASE-${arch}-ufs.qcow2.xz"
	furl="${url}${fn}"

	hashalgo="sha512"
	hashf="CHECKSUM.$(echo "${hashalgo}"| tr '[:lower:]' '[:upper:]')"
	hurl="${url}${hashf}"

	log "Starting image download"
	start="$(awk 'BEGIN{srand(); print srand()}')"
	curl --fail-with-body -s -Z -L -C - -O "$furl" 
	end="$(awk 'BEGIN{srand(); print srand()}')"
	download_time="$((end-start))"
       	log "Image downloaded"

	log "Starting hash download"
	curl --fail-with-body -s "$hurl" -o hashs.txt
       	log "Hash downloaded"
	img_hash="$("${hashalgo}sum" --tag  "${fn}")"
	img_size="$(wc -c < "${fn}" | cut -f1)"
	grep -qF "$img_hash" hashs.txt || (echo "$hash_error" && exit 1)
	rm -f hashs.txt
	log "Starting image extraction"
	xz -dkc "${fn}" > "vm-img"
	rm -f "${fn}"
	log "Image extracted"
	set +e

	# shellcheck disable=SC2016
	if [ -n "$1" ]
	then
		{
			printf '| **VM Image URL** | %s |\n' "${furl}"
			printf '| **VM Image hash (%s)** | `%s` |\n' \
				"${hashalgo}" "${img_hash}"
			printf '| **VM Image fetch time** | %ss |\n' \
				"${download_time}"
			printf '| **VM Image raw size** | %sb |\n' "${img_size}"
		} >> "${1}" 
	fi
}
image_fetch(){
	os="${VM_RUNNER_OS:=fbsd}"
	ver="${VM_RUNNER_OSVER:=15.1}"
	arch="${VM_RUNNER_ARCH:=amd64}"
	hash_error="!IMAGE HASH DOES NOT MACH!"
	"${os}_fetch" "$1"
}

