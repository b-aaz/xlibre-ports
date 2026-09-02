#!/bin/sh

dep_install () {
	apt-get update
	apt-get install \
		expect \
		qemu-utils \
		qemu-system-x86
}
