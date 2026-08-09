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
	: "${GITHUB_API_URL?}"
	: "${GITHUB_REPOSITORY?}"
	: "${GITHUB_SHA?}"
	: "${GITHUB_STEP_SUMMARY?}"
	: "${GITHUB_REF_NAME?}"
	: "${CI_ART_DIR?}"
	cmd_exe_exists_die 'gh'
	cmd_exe_exists_die 'jq'
	cmd_exe_exists_die 'patch'
}

gh_sane_api(){
	awk 'BEGIN{
		c="gh auth token"
		c|getline tok
		close c
		print "header=\"Authorization: token " tok "\""}' |
			curl -s -K - "${GITHUB_API_URL}/${1}"
}

latest_commit_json(){ leep;
	private 'jsonvar';	jsonvar="${1}"
	upvar "${jsonvar}" 'json'
	json="$(gh_sane_api "repos/${GITHUB_REPOSITORY}/commits/$GITHUB_SHA"|jq .)"
peel "${?}"; }

is_version_modified(){ leep;
	private 'jsonvar';	jsonvar="${1}"
	upvar "${jsonvar}" 'json'
	out 1 "${json}" | jq -e '
	if ( .files[] | select(.filename=="VERSION" and .status=="modified") )
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
	upvar "${jsonvar}" 'json'
	out 1 "${json}" | jq -r '(.files[] | select(.filename=="VERSION")).patch' |
		patch -R -u -o "${oldver_path}" "${ver_path}"
peel "${?}"; }

version_parse_check(){ leep;
	private 'jsonvar';		jsonvar="${1}"
	private 'ver_path';		ver_path="${2}"

	private 'message_var';		message_var="${3}"
	private 'ver_cmp_var';		ver_cmp_var="${4}"
	private 'old_ver_var';		old_ver_var="${5}"
	private 'new_ver_var';		new_ver_var="${6}"

	private '_ret';

	private 'to_dot';

	upvar "${jsonvar}" 'json'

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
	private 'htmlvar';	htmlvar="${1}"
	private 'from';		from="${2}"
	private 'to';		to="${3}"

	upvar "${htmlvar}" 'html'

	html="$(gh_sane_api "repos/${GITHUB_REPOSITORY}/compare/${from}...${to}"|
		jq -r '
		"<DETAILS><SUMMARY><H3><A href=\""
		+.html_url+
		"\">Commit log:</A></H3></SUMMARY><OL>"
		,(
			.commits?|reverse[]?|
			"<LI><DETAILS>
			   <SUMMARY><H4><A href=\"" +.html_url+ "\">"
			    +(.commit.message|split("\n\n")[0])+
			    "</A></H4> (@"+.commit.committer.name+") by @"
			    +.commit.author.name+
			   "</SUMMARY>
			   <PRE>"
			    +(.commit.message|split("\n\n")[1:]|join("\n\n"))+
			  "</PRE>
			 </DETAILS></LI>"
		),
		"</OL></DETAILS>"
		'
	)" ||_ret="${?}"

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
else
	puts "Version changed."
	do_release="true"
fi

generate_commit_log 'commit_log' "${VER_OLD}" "${GITHUB_REF_NAME}"

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
	puts '<DETAILS><SUMMARY><H3>Build information:</H3></SUMMARY>'
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
	draft_link="$(
		gh release create \
			-R "${GITHUB_REPOSITORY}" \
			-d \
			-F "${GITHUB_STEP_SUMMARY}" \
			--target "${GITHUB_REF_NAME}" \
			"${VER_NEW}" \
			"${CI_ART_DIR}"/*
	)"
fi

if [ -n "${draft_link:=}" ]; then
	puts '<H3><A href="'"${draft_link}"'">Open Release draft.</A></H3>' \
		>> "${GITHUB_STEP_SUMMARY}"
fi


# vi: ts=4 sw=4 tw=80 cc=80
