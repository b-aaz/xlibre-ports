#!/bin/sh
log() {
	echo "[$(date)] $@"
}
dfbsd_fetch() {
	set -e
	VM_RUNNER_ARCH="x86_64" # This is the only arch supported by DFBSD.
	local arch="${VM_RUNNER_ARCH}"
	local url="https://mirror-master.dragonflybsd.org/iso-images/"
	local fn="dfly-${arch}-${ver}_REL.img.bz2"
	local furl="${url}${fn}"

	local hashalgo="md5"
	local hashf="${hashalgo}.txt"
	local hurl="${url}${hashf}"

	log "Starting image download"
	local start="$(awk 'BEGIN{srand(); print srand()}')"
	curl --fail-with-body -s -Z -L -C - -O "$furl"
	local end="$(awk 'BEGIN{srand(); print srand()}')"
	local download_time="$((end-start))"
	log "Image downloaded"

	log "Starting hash download"
	curl --fail-with-body -s "$hurl" -o hashs.txt 
       	log "Hash downloaded"
	local img_hash="$("${hashalgo}sum" --tag "${fn}")"
	local img_size="$(wc -c < "${fn}" | cut -f1)"
	grep -qF "$img_hash" hashs.txt || (echo "$hash_error" && exit 1)
	rm -f hashs.txt
	log "Starting image extraction"
	bzip2 -dkc "${fn}" > "vm-img"
	rm -f "${fn}"
	log "Image extracted"
	set +e

	if [ -n "$1"]
	then
		printf '| **VM Image URL** | %s |\n' "${furl}" \
			>> "${1}" 
		printf '| **VM Image hash (%s)** | `%s` |\n' \
			"${hashalgo}" \
			"${img_hash}" \
			>> "${1}" 
		printf '| **VM Image fetch time** | %ss |\n' \
			"${download_time}" \
			>> "${1}" 
		printf '| **VM Image raw size** | %sb |\n' "${img_size}" \
			>> "${1}" 
	fi
}
fbsd_fetch() {
	set -e
	local url="https://download.freebsd.org/releases/VM-IMAGES/${ver}-RELEASE/${arch}/Latest/"
	local fn="FreeBSD-${ver}-RELEASE-${arch}-ufs.qcow2.xz"
	local furl="${url}${fn}"

	local hashalgo="sha512"
	local hashf="CHECKSUM.$(echo "${hashalgo}"| tr '[:lower:]' '[:upper:]')"
	local hurl="${url}${hashf}"

	log "Starting image download"
	local start="$(awk 'BEGIN{srand(); print srand()}')"
	curl --fail-with-body -s -Z -L -C - -O "$furl" 
	local end="$(awk 'BEGIN{srand(); print srand()}')"
	local download_time="$((end-start))"
       	log "Image downloaded"

	log "Starting hash download"
	curl --fail-with-body -s "$hurl" -o hashs.txt
       	log "Hash downloaded"
	local img_hash="$("${hashalgo}sum" --tag  "${fn}")"
	local img_size="$(wc -c < "${fn}" | cut -f1)"
	grep -qF "$img_hash" hashs.txt || (echo "$hash_error" && exit 1)
	rm -f hashs.txt
	log "Starting image extraction"
	xz -dkc "${fn}" > "vm-img"
	rm -f "${fn}"
	log "Image extracted"
	set +e

	if [ -n "$1"]
	then
		printf '| **VM Image URL** | %s |\n' "${furl}" \
			>> "${1}" 
		printf '| **VM Image hash (%s)** | `%s` |\n' \
			"${hashalgo}" \
			"${img_hash}" \
			>> "${1}" 
		printf '| **VM Image fetch time** | %ss |\n' \
			"${download_time}" \
			>> "${1}" 
		printf '| **VM Image raw size** | %sb |\n' "${img_size}" \
			>> "${1}" 
	fi
}
image_fetch(){
	local os="${VM_RUNNER_OS:=fbsd}"
	local ver="${VM_RUNNER_OSVER:=15.1}"
	local arch="${VM_RUNNER_ARCH:=amd64}"
	local hash_error="!IMAGE HASH DOES NOT MACH!"
	"${os}_fetch" "$1"
}

