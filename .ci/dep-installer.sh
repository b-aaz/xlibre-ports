#!/bin/sh

dep_install () {
	sudo apt-get update
	sudo apt-get install \
		expect \
		qemu-utils \
		qemu-system-x86
}
