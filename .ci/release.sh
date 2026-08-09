#!/bin/sh
(set -o pipefail 2>/dev/null)&&set -o pipefail
set -o errexit
cd -- "${CI_RUN_DIR?}"
sdir="$(dirname "${0}"||{ echo 'Script dir not found.'>&2;exit 1; };echo x)"
# shellcheck disable=SC1007
CDPATH= cd -- "${sdir%??}/shlib"||{ echo 'Can not cd to shlib dir.'>&2;exit 1; }

. ./indirect.sh # let, get, islet, isvar, unlet ..
. ./leeppeel.sh # leep, peel, private ...
. ./autotemp.sh # mktemp_autoclean ...
. ./basic_io.sh # out, puts, err ...
. ./cmdcheck.sh # cmd_exe_exists, cmd_exe_exists_die ...
. ./sections.sh

cd -- "${OLDPWD?}" ||{ echo 'Could not restore $PWD'>&2;exit 1; }

sanity_check(){
	: ${GITHUB_API_URL?}
	: ${GITHUB_REPOSITORY?}
	: ${GITHUB_SHA?}
	: ${GITHUB_STEP_SUMMARY?}
	: ${GITHUB_REF_NAME?}
	: ${CI_ART_DIR?}
	cmd_exe_exists_die 'curl'
	cmd_exe_exists_die 'gh'
	cmd_exe_exists_die 'jq'
	cmd_exe_exists_die 'patch'
}


latest_commit_json(){ leep;
	private 'jsonvar';	jsonvar="${1}"
	private 'json'
	puts curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA"
	json="$(
		curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA"&&
			printf 'x'
		)" && let "${jsonvar}" "${json%?}"
peel "${?}"; }

is_version_modified(){ leep;
	private 'jsonvar';	jsonvar="${1}"
	private 'json'
	get 'json' "${jsonvar}"
	out 1 "${json}" | jq -e '
	if (.files[] | select(.filename=="VERSION" and .status=="modified"))
	then
		halt
	end'
peel "${?}"; }

# Reverse applies this commits patch of the VERSION file and stores it in a file
# pointed to by oldver_path.
make_old_version(){ leep;
	private 'jsonvar';		jsonvar="${1}"
	private 'ver_path';		ver_path="${2}"
	private 'oldver_path';	oldver_path="${3}"

	private 'json'
	get 'json' "${jsonvar}"

	out 1 "${json}" |
		jq -r '(.files[]|select(.filename=="VERSION")).patch' |
		patch -R -u -o "${oldver_path}" "${ver_path}"
peel "${?}"; }

version_parse_check(){ leep;
	private 'jsonvar';		jsonvar="${1}"
	private 'ver_path';		ver_path="${2}"

	private 'message_var';		message_var="${3}"
	private 'ver_cmp_var';		ver_cmp_var="${4}"
	private 'old_ver_var';		old_ver_var="${5}"
	private 'new_ver_var';		new_ver_var="${6}"

	private 'json'

	private '_ret';

	private 'to_dot';
	get 'json' "${jsonvar}"

	mktemp_autoclean 'to_dot';

	if is_version_modified 'json'; then
		private 'oldver_path';
		mktemp_autoclean 'oldver_path';
		make_old_version "${jsonvar}" "${ver_path}" "${oldver_path}";
		./.ci/version.awk "${oldver_path}" "${ver_path}" "${message_var}" \
			"${ver_cmp_var}" "${old_ver_var}" "${new_ver_var}" \
			> "${to_dot}" ||_ret="${?}"
		. "${to_dot}"
	else
		./.ci/version.awk "${ver_path}" "${message_var}" "${old_ver_var}" \
			> "${to_dot}" ||_ret="${?}"
		. "${to_dot}"
		get "${new_ver_var}" "${old_ver_var}"
		let "${ver_cmp_var}" "="
	fi
peel _ret; }

generate_commit_log(){ leep;
	private 'htmlvar';		htmlvar="${1}"
	private 'from_ref';		from_ref="${2}"
	private 'to_ref';		to_ref="${3}"
	private 'html'

	html="$(
	curl -s\
		"$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/compare/$from_ref...$to_ref" |
		jq -r '
		"<details><summary><a href=\""
		+.html_url+
		"\"><h3>Commit log:</h3></a></summary><ol>"
		,(
			.commits?|reverse[]?|
			"<li><details>
			   <summary><a href=\"" +.html_url+ "\"><h4>"
			    +(.commit.message|split("\n\n")[0])+
			    "</h4></a> (@"+.commit.committer.name+") by @"
			    +.commit.author.name+
			   "</summary>
			   <pre>"
			    +(.commit.message|split("\n\n")[1:]|join("\n\n"))+
			  "</pre>
			 </details></li>"
		),
		"</ol></details>"
		'
	)" ||_ret="${?}"
	get "${htmlvar}" 'html' 

peel _ret; }

branch_to_name() {
	case "$1" in
		master)	echo "stable";;
		beta)	echo "beta";;
		dev)	echo "testing";;
		ci-dev)	echo "CI TESTING";;
		*)	exit 1;;
	esac
}




















sanity_check
latest_commit_json 'commit_json'
version_parse_check 'commit_json' ./VERSION 'VER_MSG' 'VER_CMP' 'VER_OLD'\
   	'VER_NEW'

section DBG
puts "MSG: ${VER_MSG}"
puts "CMP: ${VER_CMP}"
puts "OLD: ${VER_OLD}"
puts "NEW: ${VER_NEW}"
section_end

if [ "${VER_CMP?}" = "=" ]; then
	puts "Version hasn't changed"
	generate_commit_log 'commit_log' "${VER_OLD}" "${GITHUB_REF_NAME}"
else
	puts "Version changed."
	generate_commit_log 'commit_log' "${VER_OLD}" "${VER_NEW}"
	do_release="true"
fi

section DBG
puts "CMT_LOG: ${commit_log}"
section_end

section DBG
puts "DO_REL: ${do_release}"
section_end

vm_os_name="$(cat "${CI_ART_DIR}/OS.md")"

{
	printf '# %s %s (`%s`) for %s\n\n' \
		"$([ "${do_release}" = "true" ] && puts 'Release' || puts 'Build')" \
		"${VER_NEW}$([ "${do_release}" = "true" ] || puts '++')" \
		"$(branch_to_name "${GITHUB_REF_NAME}")" \
		"${vm_os_name}"

	if [ -n "${VER_MSG}" ]; then
		puts '### Version message:'
		puts "${VER_MSG}"
		puts
	fi
	puts "${commit_log?}"
	puts '<details><summary><h3>Build information:</h3></summary>'
	puts
	puts '| | |' # Headerless markdown table.
	puts '|-|-|'
	cat "${CI_ART_DIR}/build_info.md"
	cat "${CI_ART_DIR}/host_info.md"
	puts
	puts '</details>'
} >> "${GITHUB_STEP_SUMMARY}"
rm  "${CI_ART_DIR}"/*.md

if [ "${do_release}" = "true" ]; then
	gh release create \
		-d \
		-F "${GITHUB_STEP_SUMMARY}" \
		--target "${GITHUB_REF_NAME}" \
		"${VER_NEW}" \
		"${CI_ART_DIR}"/*
fi

# vi: ts=4 sw=4 tw=80 cc=80
