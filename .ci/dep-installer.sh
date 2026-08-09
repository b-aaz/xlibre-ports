#!/bin/sh

dep_install () {
	apt-get update  -qq -o=Dpkg::Use-Pty=0
	apt-get install -qq -o=Dpkg::Use-Pty=0 \
		expect \
		qemu-utils \
		qemu-system-x86
}

# vi: ts=4 sw=4 tw=80 cc=80
