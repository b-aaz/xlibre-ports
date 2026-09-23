#!/bin/sh
version_changed(){
	curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA" |
		jq -e '
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
		echo '<details>
		<summary>Build information</summary>'
		cat "${CI_ART_DIR}/build_info.md"
		cat "${CI_ART_DIR}/host_info.md"
		echo '</details>'
	} >> "${GITHUB_STEP_SUMMARY}"

	rm  "${CI_ART_DIR}"/*.md 
fi
