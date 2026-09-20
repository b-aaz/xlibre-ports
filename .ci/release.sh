#!/bin/sh

curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA" |
       	jq -e '
if (.files[] | select(.filename=="VERSION" and .status=="modified")) then
	halt
end' && {
	find "${CI_ART_DIR}"
} || {
	echo "Version hasn't changed, doing nothing."
	cat "${CI_ART_DIR}/build_info.md"
	cat "${CI_ART_DIR}/build_info.md" > "${GITHUB_STEP_SUMMARY}"
}
