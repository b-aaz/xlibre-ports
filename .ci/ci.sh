#!/bin/sh

ls
df -h
cd ./.ci/
. ./image-fetcher.sh
. ./dep-installer.sh

dep_install &
image_fetch &
ssh-keygen -t ed25519 -N '' &
wait
ls
./vm-exp/vm.exp \
	./vm-scripts/bootloader_cmds \
	./vm-scripts/singleuser_fbsd_cmds \
	./vm-scripts/normal_cmds \
	./vm-runner.sh

ssh-keyscan -p 10022 127.0.0.1
ssh-keyscan -p 10022 root@127.0.0.1 uname -a
