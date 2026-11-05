#!/bin/sh
# shellcheck enable=deprecate-which
# shellcheck enable=add-default-case
# shellcheck enable=avoid-negated-conditions
# shellcheck enable=check-extra-masked-returns
# shellcheck enable=quotes-safe-variables
# shellcheck enable=require-variable-braces
# \/ For allowing the use of let. \/
# shellcheck disable=SC3039




# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null)&&set -o pipefail
set -o errexit
cd -- "${CI_RUN_DIR?}"
sdir="$(dirname "${0}"||{ echo 'Script dir not found.'>&2;exit 1; };echo x)"
# shellcheck disable=SC1007
CDPATH= cd -- "${sdir%??}/shlib"||{ echo 'Can not cd to shlib dir.'>&2;exit 1; }

# \/ Don't notify about dotted scripts and -x. \/
# shellcheck disable=SC1091
{
	. ./indirect.sh # let, get, islet, isvar, unlet ..
	. ./leeppeel.sh # leep, peel, private ...
	. ./autotemp.sh # mktemp_autoclean ...
	. ./basic_io.sh # out, puts, err ...
	. ./cmdcheck.sh # cmd_exe_exists, cmd_exe_exists_die ...
	. ./sections.sh
}
# shellcheck disable=SC2016
cd -- "${OLDPWD?}" ||{ echo 'Could not restore $PWD'>&2;exit 1; }

sanity_check(){
	: "${GITHUB_API_URL?}"
	: "${GITHUB_SERVER_URL?}"
	: "${GITHUB_REPOSITORY?}"
	: "${GITHUB_SHA?}"
	: "${GITHUB_STEP_SUMMARY?}"
	: "${GITHUB_REF_NAME?}"
	: "${CI_ART_DIR?}"
	cmd_exe_exists_die 'gh'
	cmd_exe_exists_die 'jq'
	cmd_exe_exists_die 'patch'
	cmd_exe_exists_die 'curl'
	cmd_exe_exists_die 'git'
}

ref_exists(){
	git ls-remote --exit-code \
		"${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}" "${1}" \
		2> /dev/null > /dev/null
}

gh_sane_api(){
	awk 'BEGIN{
		c="gh auth token"
		c|getline tok
		close(c)
		print "header=\"Authorization: token " tok "\""}' |
			curl -s -K - "${GITHUB_API_URL}/${1}"
}

latest_commit_json(){ leep;
	private 'jsonvar';	jsonvar="${1}"
	upvar "${jsonvar}" 'json'
	json="$(gh_sane_api "repos/${GITHUB_REPOSITORY}/commits/${GITHUB_SHA}")"
peel "${?}"; }

is_version_modified(){ leep;
	private 'jsonvar';	jsonvar="${1}"
	upvar "${jsonvar}" 'json'
	out 1 "${json}" | jq -e '
	if ( .files[] | select(.filename=="VERSION.md" and .status=="modified") )
	then
		halt
	end'
peel "${?}"; }

# Reverse applies this commits patch of the VERSION.md file and stores it in a
# file pointed to by oldver_path.
make_old_version(){ leep;
	private 'jsonvar';		jsonvar="${1}"
	private 'ver_path';		ver_path="${2}"
	private 'oldver_path';	oldver_path="${3}"
	upvar "${jsonvar}" 'json'
	out 1 "${json}" | jq -r '(.files[]|select(.filename=="VERSION.md")).patch'|
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
	: "${to_dot:?}"

	if is_version_modified 'json'; then
		private 'oldver_path';
		mktemp_autoclean 'oldver_path';
		: "${oldver_path:?}"
		make_old_version "${jsonvar}" "${ver_path}" "${oldver_path}";
		./.ci/version.awk "${oldver_path}" "${ver_path}" "${message_var}" \
			"${ver_cmp_var}" "${old_ver_var}" "${new_ver_var}" \
			> "${to_dot}" ||_ret="${?}"
		# shellcheck disable=SC1090
		. "${to_dot}"
	else
		./.ci/version.awk "${ver_path}" "${message_var}" "${old_ver_var}" \
			> "${to_dot}" ||_ret="${?}"
		# shellcheck disable=SC1090
		. "${to_dot}"
		get "${new_ver_var}" "${old_ver_var}"
		let "${ver_cmp_var}" "="
	fi
peel _ret; }

generate_commit_log(){ leep;while :;do
	private 'htmlvar';	htmlvar="${1}"
	private 'from';		from="${2}"
	private 'to';		to="${3}"

	upvar "${htmlvar}" 'html'

	ref_exists "${from}" ||{
		_ret=$?;err "Remote starting ref '${from}' not found"; break; }
	ref_exists "${to}" ||{
		_ret=$?;err "Remote ending ref '${to}' not found"; break; }

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
	: "${html?}"

break;done;peel _ret; }

branch_to_name() {
	case "${1}" in
		master)	puts "stable";;
		beta)	puts "beta";;
		dev)	puts "testing";;
		ci-dev)	puts "CI TESTING";;
		*)	false;exit;;
	esac
	true
}





















sanity_check
latest_commit_json 'commit_json'
version_parse_check 'commit_json' ./VERSION.md 'VER_MSG' 'VER_CMP' 'VER_OLD'\
	'VER_NEW'

section DBG-VER
puts "MSG: ${VER_MSG}"
puts "CMP: ${VER_CMP}"
puts "OLD: ${VER_OLD}"
puts "NEW: ${VER_NEW}"
section_end

# shellcheck disable=SC2015
[ "${1}" = "final" ] &&
	readonly final_release='true' ||
	readonly final_release='false'
# shellcheck disable=SC2015
[ "${1}" = "cleanup" ] &&
	readonly cleanup='true' ||
	readonly cleanup='false'
# shellcheck disable=SC2015
[ "${VER_CMP?}" != "=" ] &&
	{ puts "Version has changed."  ; readonly do_release="true"; } ||
	{ puts "Version hasn't changed"; readonly do_release="false"; }

section DBG-REL
puts "do_release:	${do_release}"
puts "final_release:	${final_release}"
puts "cleanup:	${cleanup}"
section_end

export GH_REPO="${GITHUB_REPOSITORY}"
err 'dbg: Set default repo to:' "${GH_REPO}"


if "${cleanup}" && "${do_release}"; then
	err 'dbg: Deleting any leftover releases.'
	if gh release view "${VER_NEW}" >/dev/null
	then
		gh release delete "${VER_NEW}" -y
		err 'dbg: Deleted a leftover release.'
	fi
	true;exit
fi



if "${final_release}"; then
	err 'dbg: Final release.'
	if "${do_release}"; then
		err 'dbg: Doing final step.'
		{
			# shellcheck disable=SC2016
			# shellcheck disable=SC2312
			printf '# Release %s (`%s`).\n\n' \
				"${VER_NEW}" "$(branch_to_name "${GITHUB_REF_NAME}")"\

				gh release view "${VER_NEW}" --json body | jq -r '.body'

			if [ -n "${VER_MSG}" ]; then
				puts '### Version message:'
				puts "${VER_MSG}"
				puts
			fi
			generate_commit_log 'commit_log' "${VER_OLD}" "${GITHUB_REF_NAME}"
			puts "${commit_log?}"
		} >> "${GITHUB_STEP_SUMMARY}"
		gh release edit "${VER_NEW}" -F "${GITHUB_STEP_SUMMARY}"
	fi
else
	err 'dbg: Release step.'
	vm_os_name="$(cat "${CI_ART_DIR}/OS.md")"
	{
		printf '## Build for %s\n\n' \
			"${vm_os_name}"

		puts '<DETAILS><SUMMARY><H3>Build information:</H3></SUMMARY>'
		puts
		puts '| | |' # Headerless markdown table.
		puts '|-|-|'
		cat "${CI_ART_DIR}/build_info.md"
		cat "${CI_ART_DIR}/host_info.md"
		puts
		puts '</details>'

	} >> "${GITHUB_STEP_SUMMARY}"
	err 'dbg: Generated step summary (only build info).'
	rm  "${CI_ART_DIR}"/*.md

	if "${do_release}"; then
		err 'dbg: Doing partial release uploads.'
		# Create the actual release in case we haven't already.
		gh release view "${VER_NEW}" >/dev/null || gh release create \
			-R "${GITHUB_REPOSITORY}" \
			-d \
			--target "${GITHUB_REF_NAME}" \
			"${VER_NEW}"
		mktemp_autoclean 'notes_file'
		: "${notes_file:?}"

		gh release view "${VER_NEW}" --json body|jq -r '.body' > "${notes_file}"
		cat "${GITHUB_STEP_SUMMARY}" >> "${notes_file}"
		gh release edit "${VER_NEW}" -F "${notes_file}"

		err 'dbg: Uploading files:'
		#shellcheck disable=2210
		find "${CI_ART_DIR}" || true
		gh release upload "${VER_NEW}" "${CI_ART_DIR}"/*
		err 'dbg: Done partial release uploads.'

	else
		err 'dbg: Generating the complete build step summary'
		current_notes="$(cat "${GITHUB_STEP_SUMMARY}"; printf 'x')"
		current_notes="${current_notes%?}"
		{

			# shellcheck disable=SC2016
			# shellcheck disable=SC2312
			printf '# Build %s++ (`%s`).\n\n' \
				"${VER_NEW}" "$(branch_to_name "${GITHUB_REF_NAME}")"

			puts "${current_notes}"

			if [ -n "${VER_MSG}" ]; then
				puts '### Version message:'
				puts "${VER_MSG}"
				puts
			fi
			generate_commit_log 'commit_log' "${VER_OLD}" "${GITHUB_REF_NAME}"
			puts "${commit_log?}"
		} > "${GITHUB_STEP_SUMMARY}"
		err 'dbg: Generated the complete build step summary'
	fi
fi


# vi: ts=4 sw=4 tw=80 cc=80
