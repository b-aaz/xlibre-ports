#!/bin/sh

dep_install () {
	apt-get update  -q -o=Dpkg::Use-Pty=0
	apt-get install -q -o=Dpkg::Use-Pty=0 \
		expect \
		qemu-utils \
		qemu-system-x86
}
