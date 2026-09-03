#!/bin/sh

s_dir=${0%/*}; [ "$s_dir" = "$0" ] && s_dir='.'
cd "$s_dir"
. ./image-fetcher.sh
. ./dep-installer.sh
. ./print-utils.sh

case $1 in
	fbsd)
		export VM_RUNNER_OS='fbsd'
		export VM_RUNNER_OSVER='15.1'
		export VM_RUNNER_ARCH='amd64'
		;;
	dfbsd)
		export VM_RUNNER_OS='dfbsd'
		export VM_RUNNER_OSVER='6.4.2'
		export VM_RUNNER_ARCH='x86_64'
		;;
	*)
		exit 1
		;;
esac


section VM-PRERUN
ssh-keygen -f ~/.ssh/id_ed25519 -t ed25519 -N '' &
dep_install &
image_fetch &
wait
section_end

section VM-SETUP
./vm-exp/vm.exp \
	./vm-scripts/bootloader_cmds \
	./vm-scripts/singleuser_${VM_RUNNER_OS}_cmds \
	./vm-scripts/normal_cmds \
	./vm-runner.sh
ssh-keyscan -p 10022 127.0.0.1 >> ~/.ssh/known_hosts
section_end

printenv | grep '^GITHUB.*=\|^CI.*=' > host-env
scp -P  10022 host-env root@127.0.0.1:/root/.ssh/environment
ssh -p  10022 root@127.0.0.1      mkdir -p /opt/ci-run/
scp -pP 10022 ./in-vm-ci.sh root@127.0.0.1:/opt/ci-run/in-vm-ci.sh
ssh -p  10022 root@127.0.0.1      /bin/sh  /opt/ci-run/in-vm-ci.sh
