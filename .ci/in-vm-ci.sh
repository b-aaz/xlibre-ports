#!/bin/sh

echo Hello form VM.
echo
printenv
uname -A


[ "${GITHUB_ACTIONS}" = "true" ] && echo '::group::Inner Clone'
mkdir -p /opt/ci-run/
fetch -o - $GITHUB_API_URL/repos/$GITHUB_REPOSITORY/tarball/$GITHUB_REF | tar -xvz --strip-components=1 -C /opt/ci-run/
[ "${GITHUB_ACTIONS}" = "true" ] && echo '::endgroup::'

ls /opt/ci-run/
