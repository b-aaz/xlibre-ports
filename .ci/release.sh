#!/bin/sh

export -p; echo "$0; $LINENO" #DEBUG
curl -s "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA" |
       	jq -e '
if (.files[] | select(.filename=="VERSION" and .status=="modified")) then
	halt
end' && {
	find "${CI_ART_DIR}"
} || {
	echo "Version hasn't changed, doing nothing."
}
