#!/bin/sh

curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA" |
       	jq -e '
if (.files[] | select(.filename=="VERSION" and .status=="modified")) then
	halt
end' && {
	find "${CI_ART_DIR}"
} || {
	echo "Version hasn't changed, doing nothing."
	cat "${CI_ART_DIR}/header.md" >> "${GITHUB_STEP_SUMMARY}"
	echo '<details>
	<summary>Build information</summary>' >> "${GITHUB_STEP_SUMMARY}"
	cat "${CI_ART_DIR}/build_info.md" >> "${GITHUB_STEP_SUMMARY}"
	cat "${CI_ART_DIR}/host_info.md" >> "${GITHUB_STEP_SUMMARY}"
	echo '</details>' >> "${GITHUB_STEP_SUMMARY}"
	rm  "${CI_ART_DIR}/*.md" 
}
