#!/bin/sh
(set -o pipefail 2>/dev/null)&&set -o pipefail
set -o errexit



cd "${CI_RUN_DIR}/.ci/shlib/"
. ./sections.sh # section, section_end ...
. ./autotemp.sh # mktemp_autoclean ...
cd "${CI_RUN_DIR}/.ci/"
. ./image-fetcher.sh
. ./dep-installer.sh

run_ci()
{
	cd "${CI_RUN_DIR}/.ci/" rm -rf -- "${CI_ART_DIR:?}"
	mkdir -p "${CI_ART_DIR}"

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

	# Setting up a temp dir for ssh.
	mktemp_autoclean 'ssh_home' -d
	ssh_dir="${ssh_home:?}/.ssh"
	mkdir "${ssh_dir}"
	chmod 700 "${ssh_dir}"

	ssh_key="${ssh_dir}/id_ed25519"
	ssh_pub="${ssh_dir}/id_ed25519.pub"
	ssh_hosts="${ssh_dir}/known_hosts"
	ssh_conf="${ssh_dir}/config"

	puts "
UserKnownHostsFile ${ssh_hosts}
IdentityFile ${ssh_key}
IdentitiesOnly yes
" > "${ssh_conf}"


	section VM-PRERUN
	(
		ssh-keygen -f "${ssh_key}" -t ed25519 -N ''& keygen_pid="$!"
		image_fetch "${CI_ART_DIR}/host_info.md"& fetch_pid="$!"
		dep_install& dep_pid="$!"

		wait "$dep_pid"; wait "$keygen_pid"; wait "$fetch_pid"
	)
	section_end

	section VM-SETUP
	{
		nice -n 18 \
			"${CI_RUN_DIR}/.ci/vm-exp/vm.exp" \
				"${CI_RUN_DIR}/.ci/vm-scripts/bootloader_cmds" \
				"${CI_RUN_DIR}/.ci/vm-scripts/singleuser_${VM_RUNNER_OS}_cmds" \
				"${CI_RUN_DIR}/.ci/vm-scripts/normal_cmds" \
				"${ssh_pub}" \
				"${CI_RUN_DIR}/.ci/vm-runner.sh"

		ssh-keyscan -p 10022 127.0.0.1 >> "${ssh_hosts}"
	}
	section_end
	time_to_boot="${SECTION_TIME}"

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


	scp -F "${ssh_conf}" -P 10022 vm-env        root@127.0.0.1:/tmp/vm-env
	scp -F "${ssh_conf}" -P 10022 in-vm-ci.sh   root@127.0.0.1:/tmp/in-vm-ci.sh

	ssh -F "${ssh_conf}" -np 10022 root@127.0.0.1\
		'/bin/sh -c ". /tmp/vm-env;exec /bin/sh /tmp/in-vm-ci.sh"'

	scp -F "${ssh_conf}" -rpP 10022 \
		"root@127.0.0.1:${CI_ART_DIR}/*" "${CI_ART_DIR}/"

	printf '| **Time to boot** | %ss |\n'	"${time_to_boot}" \
		>>"${CI_ART_DIR}/host_info.md"

	find "${CI_ART_DIR}"
}

wipe_ci(){
	echo '!!!!!!!!!!Wiping CI files & recloning files!!!!!!!!!!!'
	cd  -- /tmp/
	rm -rf -- "${CI_ART_DIR:?}"
	rm -rf -- "${CI_RUN_DIR:?}"
	mkdir -p  "${CI_RUN_DIR}"
	cd  -- "${CI_RUN_DIR}"

	section RECLONE
	ls "${CI_RUN_DIR}"
	curl -L "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/tarball/$GITHUB_REF" |\
		tar -xz --strip-components=1 -C "${CI_RUN_DIR}"
	ls "${CI_RUN_DIR}"
	section_end
}

ci_killer(){
	sleep $((30*60))
	echo '!!!!!!!!!!Timeout, Killing running CI!!!!!!!!!!!'
	if kill -0 "${1}" 2>/dev/null;
	then
		echo '!!!!!!!!!!PID found, killing!!!!!!!!!!!'
		( kill "${1}"; sleep 1;  kill -9 "${1}")&
		(pkill 'qemu'; sleep 1; pkill -9 'qemu')&
	fi
}


for run_repeat in 3 2 1 0
do
	( run_ci "$@" )&
	ci_pid=$!

	ci_killer "${ci_pid}"&

	wait "${ci_pid}" && {
		kill -9 "$(jobs -p)"||true; break
	} || wipe_ci
	kill -9 "$(jobs -p)"||true

	echo              '!!!!!!!!!!CI timedout/failed!!!!!!!!!!!'
	if [ "${run_repeat}" -ne 0 ]; then
		echo "!!!!!!!!!!Reruning for ${run_repeat} more times!!!!!!!!!!!"
	else
		false;exit
	fi
done

# vi: ts=4 sw=4 tw=80 cc=80
