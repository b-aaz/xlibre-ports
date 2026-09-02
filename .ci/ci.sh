#!/bin/sh

cd /opt/ci-run/
cd ./.ci/
. ./image-fetcher.sh
. ./dep-installer.sh

ssh-keygen -f ~/.ssh/id_ed25519 -t ed25519 -N '' &
dep_install &
image_fetch &
wait
./vm-exp/vm.exp \
	./vm-scripts/bootloader_cmds \
	./vm-scripts/singleuser_fbsd_cmds \
	./vm-scripts/normal_cmds \
	./vm-runner.sh

ssh-keyscan -p 10022 127.0.0.1 && echo KEY SCAN DONE
ssh -p 10022 root@127.0.0.1 uname -a
