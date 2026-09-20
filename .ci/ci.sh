#!/bin/sh
set -ex

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
	set -f
	# Here we first create a list of env var keys that we want to remove
	# based on two regex patterns (one negative and one positive).
	for key in $(awk 'BEGIN{for(key in ENVIRON){
		if( !match(key,/^GITHUB|^CI/) || match(key,/TOKEN|SECRET/) ){
			print key
		}}}')
	do
		#  then we unset them in this sub shell,
		unset -v "${key}"
	done
	#  and we use export -p to
	export -p > vm-env # make a env file of what remains to send to the VM.

)
scp -P  10022 vm-env        root@127.0.0.1:/tmp/vm-env
scp -P  10022 in-vm-ci.sh   root@127.0.0.1:/tmp/in-vm-ci.sh

ssh -p 10022 root@127.0.0.1\
	'/bin/sh -c ". /tmp/vm-env;exec /bin/sh /tmp/in-vm-ci.sh"'

mkdir -p "${CI_ART_DIR:?}"
scp -rpP 10022 "root@127.0.0.1:${CI_ART_DIR}/*" "${CI_ART_DIR}/"
find "${CI_ART_DIR}"; echo "$0; $LINENO" #DEBUG
