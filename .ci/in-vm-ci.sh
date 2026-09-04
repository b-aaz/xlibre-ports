#!/bin/sh

[ "${GITHUB_ACTIONS}" = "true" ] && echo '::group::Inner Clone'
mkdir -p /opt/ci-run/
fetch -o - $GITHUB_API_URL/repos/$GITHUB_REPOSITORY/tarball/$GITHUB_REF | tar -xvz --strip-components=1 -C /opt/ci-run/
[ "${GITHUB_ACTIONS}" = "true" ] && echo '::endgroup::'

cd /opt/ci-run/
. ./.ci/print-utils

case "$(uname -s)" in
	FreeBSD*)
		PORTS_REPO="freebsd/freebsd-ports"
		PORTS_BRANCH="refs/heads/2026Q2"
		;;
	DragonFly*)
		PORTS_REPO="DragonFlyBSD/DeltaPorts"
		PORTS_BRANCH="refs/heads/master"
		;;
	*)
		exit 1
		;;
esac



section CLONE-PORTS
mkdir -p /usr/ports/
rm -rf   /usr/ports/*
fetch -o - $GITHUB_API_URL/repos/$PORTS_REPO/tarball/$PORTS_BRANCH | tar -xvz --strip-components=1 -C /usr/ports
section_end

ls /usr/ports/
