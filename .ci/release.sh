#!/bin/sh
(set -o pipefail 2>/dev/null)&&set -o pipefail
set -o errexit

version_changed(){
	json="$(
	curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA"
	)"

	printf '%s\n' "$json" | jq -e '
	if (.files[] | select(.filename=="VERSION" and .status=="modified"))
	then
		halt
	end' 
}

if version_changed
then
	echo "Version changed."
	find "${CI_ART_DIR}"
else
	echo "Version hasn't changed, doing nothing."

	{
		cat "${CI_ART_DIR}/header.md"
		echo '<details><summary>Build information</summary>'
		echo
		echo '| | |' # Headerless markdown table.
		echo '|-|-|'
		cat "${CI_ART_DIR}/build_info.md"
		cat "${CI_ART_DIR}/host_info.md"
		echo
		echo '</details>'
	} >> "${GITHUB_STEP_SUMMARY}"

	rm  "${CI_ART_DIR}"/*.md 
fi
