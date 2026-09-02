#!/bin/sh

ls
cd ./.ci/
. ./image-fetcher.sh

image_fetch
ls
./vm-exp/vm.exp \
	./vm-scripts/bootloader_cmds \
	./vm-scripts/singleuser_fbsd_cmds \
	./vm-scripts/normal_cmds \
	./vm-runner.sh

ssh-keyscan -p 10022 127.0.0.1
ssh-keyscan -p 10022 root@127.0.0.1 uname -a
