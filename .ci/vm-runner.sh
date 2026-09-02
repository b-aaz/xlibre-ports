#!/bin/sh
# This script takes a single optional argument as the VM image to run, if not
# present it will default to a image named 'vm.img'.

export TERM=ASCII # To maybe lessen the escape codes in the logs.
nproc="${VM_RUNNER_CPUS:=$(getconf _NPROCESSORS_ONLN)}"
mem="${VM_RUNNER_MEM:=7G}"
img="${1:-${VM_RUNNER_IMG_FILE:=vm-img}}"
img_typ="${VM_RUNNER_IMG_TYPE:="$(qemu-img info "$img" | sed -n 's/file format:\s*//p')"}"
size="${VM_RUNNER_IMG_SIZE:=11G}"
qemu-img resize -f "$img_typ" "$img" "$size"
qemu-system-x86_64 \
	-boot menu=off,splash-time=0,strict=on,order=c \
	-device e1000,netdev=n1 \
	-netdev user,id=n1,hostfwd=tcp:127.0.0.1:10022-:22 \
       	-machine q35,accel=kvm:tcg \
	-m "$mem" \
	-smp "$nproc" \
	-monitor none \
	-drive file="$img",if=virtio \
	-nographic \
	-serial stdio
