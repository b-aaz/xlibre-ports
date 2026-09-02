#!/bin/sh
log() {
	echo "[$(date)] $@"
}
dfbsd_fetch() {
	set -e
	VM_RUNNER_ARCH="amd64" # This single arch supported by DFBSD.
	arch="${VM_RUNNER_ARCH}"
	full_arch="${arch}"
	local fn="dfly-x86_64-${ver}_REL.img.bz2"
	local hashf="md5.txt"
	local url="https://mirror-master.dragonflybsd.org/iso-images/"
	local hurl="${url}${hashf}"
	local furl="${url}${fn}"
	log "Starting image download"
	curl --fail-with-body -s -Z -L -C - -O "$furl"
	log "Image downloaded"
	log "Starting hash download"
	curl --fail-with-body -s "$hurl" -o hashs.txt 
       	log "Hash downloaded"
	img_hash="$(md5sum --tag "${fn}")"
	grep -qF "$img_hash" hashs.txt || (echo "$hash_error" && exit 1)
	rm -f hashs.txt
	export VM_RUNNER_IMG_FILE="${os}-${full_arch}-${ver}.img"
	log "Starting image extraction"
	bzip2 -dkc "${fn}" > "${VM_RUNNER_IMG_FILE}"
	rm -f "${fn}"
	log "Image extracted"
	set +e
}
fbsd_fetch() {
	set -e
	local fn="FreeBSD-${ver}-RELEASE-${arch}-ufs.qcow2.xz"
	local hashf="CHECKSUM.SHA512"
	local url="https://download.freebsd.org/releases/VM-IMAGES/${ver}-RELEASE/${arch}/Latest/"
	local hurl="${url}${hashf}"
	local furl="${url}${fn}"
	log "Starting image download"
	curl --fail-with-body -s -Z -L -C - -O "$furl" 
       	log "Image downloaded"
	log "Starting hash download"
	curl --fail-with-body -s "$hurl" -o hashs.txt
       	log "Hash downloaded"
	img_hash="$(sha512sum --tag "${fn}")"
	grep -qF "$img_hash" hashs.txt || (echo "$hash_error" && exit 1)
	rm -f hashs.txt
	export VM_RUNNER_IMG_FILE="${os}-${full_arch}-${ver}.qcow2"
	log "Starting image extraction"
	xz -dkc "${fn}" > "${VM_RUNNER_IMG_FILE}"
	rm -f "${fn}"
	log "Image extracted"
	set +e
}
image_fetch(){
	local os="${VM_RUNNER_OS:=fbsd}"
	local ver="${VM_RUNNER_OSVER:=15.1}"
	local arch="${VM_RUNNER_ARCH:=amd64}"
	local full_arch="${VM_RUNNER_ARCH:="${arch}"}"
	local hash_error="!IMAGE HASH DOES NOT MACH!"
	"${os}_fetch"
}

