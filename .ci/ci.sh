#!/bin/sh

s_dir=${0%/*}; [ "$s_dir" = "$0" ] && s_dir='.'
cd "$s_dir"
. ./image-fetcher.sh
. ./dep-installer.sh
. ./print-utils.sh

section VM-PRERUN
ssh-keygen -f ~/.ssh/id_ed25519 -t ed25519 -N '' &
dep_install &
image_fetch &
wait
section_end

section VM-SETUP
./vm-exp/vm.exp \
	./vm-scripts/bootloader_cmds \
	./vm-scripts/singleuser_fbsd_cmds \
	./vm-scripts/normal_cmds \
	./vm-runner.sh
ssh-keyscan -p 10022 127.0.0.1 >> ~/.ssh/known_hosts
section_end

ssh -p 10022 root@127.0.0.1 uname -a
