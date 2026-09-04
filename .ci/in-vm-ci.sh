#!/bin/sh

[ "${GITHUB_ACTIONS}" = "true" ] && echo '::group::INNER-CLONE'
mkdir -p "${CI_RUN_DIR:?}"
fetch -o - "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/tarball/$GITHUB_REF" | \
       	tar -xvz --strip-components=1 -C "${CI_RUN_DIR}"
[ "${GITHUB_ACTIONS}" = "true" ] && echo '::endgroup::'
cd "${CI_RUN_DIR}"

. ./.ci/print-utils.sh

case "$(uname -s)" in
	FreeBSD*)
		PORTS_REPO="freebsd/freebsd-ports"
		PORTS_BRANCH="refs/heads/2026Q2"
		PORTS_DIR="/usr/ports"
		FLITTERED_DEPS='x11/plasma6-plasma\|x11/plasma6-plasma-desktop'
		;;
	DragonFly*)
		PORTS_REPO="DragonFlyBSD/dports"
		PORTS_BRANCH="refs/heads/master"
		PORTS_DIR="/usr/dports"
		FLITTERED_DEPS='ports-mgmt/pkg'
		;;
	*)
		exit 1
		;;
esac



section CLONE-PORTS
mkdir -p "$PORTS_DIR"
rm -rf   "${PORTS_DIR:?}/*"
fetch -o - "$GITHUB_API_URL/repos/$PORTS_REPO/tarball/$PORTS_BRANCH" | \
	tar -xz --strip-components=1 -C "$PORTS_DIR"
section_end

section PORTS-PATCH
{
	{
		patch -N "${PORTS_DIR}/Mk/bsd.port.subdir.mk" <\
		       	./.ci/bsd.port.subdir.mk.patch
	} || true
}

{
	{
		patch -N "${PORTS_DIR}/Mk/bsd.port.mk" < ./.ci/bsd.port.mk.patch
	} || true
}
section_end

section MAKE-CONFIG
cat > /etc/make.conf << EOF
OVERLAYS="${CI_RUN_DIR}"
BATCH=yes
PACKAGES="${CI_RUN_DIR}/pkgs"
EOF
section_end

section RUN-DEP-INSTALL
make run-depends-list |\
	sort |\
	uniq |\
	grep -v '^==\|xlibre' |\
	awk -F "/" '{print $(NF-1) "/" $NF}' |\
	grep -v "$FLITTERED_DEPS" |\
	xargs pkg-static install -y
section_end

section BUILD-DEP-INSTALL
make build-depends-list |\
	sort |\
	uniq |\
	grep -v '^==\|xlibre' |\
	awk -F "/" '{print $(NF-1) "/" $NF}' |\
	grep -v "$FLITTERED_DEPS" |\
	xargs pkg-static install -y
section_end

section STAGE
make stage
section_end

section STAGE-QA
make stage-qa
section_end

section CHECK-PLIST
make check-plist
section_end

section PACKAGES
make packages
section_end

