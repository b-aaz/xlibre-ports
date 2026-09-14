#!/bin/sh
set -e

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
	fbsd-legacy)
		export VM_RUNNER_OS='fbsd'
		export VM_RUNNER_OSVER='14.5'
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
	"./vm-scripts/singleuser_${VM_RUNNER_OS}_cmds" \
	./vm-scripts/normal_cmds \
	./vm-runner.sh
ssh-keyscan -p 10022 127.0.0.1 >> ~/.ssh/known_hosts
section_end

(
	# Here we first create a list of env var keys that we want to remove
	# based on two regex patterns (one negative and one positive).
	awk 'BEGIN{for(name in ENVIRON){if(
		!match(name,"^GITHUB\|^CI")
		||
		match(name,"TOKEN\|SECRET")
		){print name}}}' | while read -r key
	do
	#  then we unset them in this sub shell,
		unset -v "${key}"
	done
	#  and we use export -p to make a env file of what remains to send to
	#  the VM.
	export -p > vm-env

)
scp -P  10022 vm-env         root@127.0.0.1:/tmp/vm-env
export -p #DEBUG
cat in-vm-ci.sh | ssh -p 10022 root@127.0.0.1  '. /tmp/vm-env;exec /bin/sh -s'
mkdir -p "${CI_ART_DIR:?}"
scp -rpP 10022 "root@127.0.0.1:${CI_ART_DIR}" "${CI_ART_DIR}" 
find "${CI_ART_DIR}" #DEBUG
