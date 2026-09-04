#!/bin/sh

[ "${GITHUB_ACTIONS}" = "true" ] && echo '::group::INNER-CLONE'
mkdir -p "${CI_RUN_DIR:?}"
fetch -o - "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/tarball/$GITHUB_REF" | \
       	tar -xvz --strip-components=1 -C "${CI_RUN_DIR}"
[ "${GITHUB_ACTIONS}" = "true" ] && echo '::endgroup::'
cd "${CI_RUN_DIR}"

. ./.ci/print-utils.sh

REPO_DIR="${CI_RUN_DIR}/pkgs"
case "$(uname -s)" in
	FreeBSD*)
		PORTS_REPO="freebsd/freebsd-ports"
		PORTS_BRANCH="refs/heads/2026Q3"
		PORTS_DIR="/usr/ports"
		FLITTERED_DEPS='x11/plasma6-plasma\|x11/plasma6-plasma-desktop'
		;;
	DragonFly*)
		PORTS_REPO="DragonFlyBSD/dports"
		PORTS_BRANCH="refs/heads/master"
		PORTS_DIR="/usr/dports"
		FLITTERED_DEPS='ports-mgmt/pkg'
		pkg lock -qy pkg # HACK, cause DFBSD's updated 'pkg' is broken.
		;;
	*)
		exit 1
		;;
esac



section CLONE-PORTS
{
	mkdir -p "$PORTS_DIR"
	rm -rf   "${PORTS_DIR:?}/*"
	fetch -o - "$GITHUB_API_URL/repos/$PORTS_REPO/tarball/$PORTS_BRANCH" | \
		tar -xz --strip-components=1 -C "$PORTS_DIR"
}
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
{
	tee /etc/make.conf << EOF
OVERLAYS=${CI_RUN_DIR}
BATCH=yes
PACKAGES=${REPO_DIR}
EOF
}
section_end

section RUN-DEP-INSTALL
{
	make run-depends-list |\
		sort |\
		uniq |\
		grep -v '^==\|xlibre' |\
		awk -F "/" '{print $(NF-1) "/" $NF}' |\
		grep -v "$FLITTERED_DEPS" |\
		xargs pkg-static install -y
}
section_end

section BUILD-DEP-INSTALL
{
	make build-depends-list |\
		sort |\
		uniq |\
		grep -v '^==\|xlibre' |\
		awk -F "/" '{print $(NF-1) "/" $NF}' |\
		grep -v "$FLITTERED_DEPS" |\
		xargs pkg-static install -y
}
section_end

section STAGE
{
	make stage || exit 1
}
section_end

section STAGE-QA
{
	make stage-qa || exit 1
}
section_end

section CHECK-PLIST
{
	make check-plist || exit 1
}
section_end

section PACKAGES
{
	mkdir -p "${REPO_DIR}"
	make package || exit 1
}
section_end

section REPO-CREATION
{
	pkg-static install -y tree
	ABI="$(pkg config abi)"
	mv "$REPO_DIR/All" "$REPO_DIR/$ABI"
	cd "$REPO_DIR/$ABI" || exit 1
	pkg repo . || exit 1
	title_msg="XLibre repository for $OS_NAME "\
		"$(echo "$ABI" | cut -d: -f 2- | tr ':' ' ')"

	tree -hDCH -./ --houtro=/dev/null -T "${title_msg}" ./ > ./index.html
}
section_end

tree "${REPO_DIR}"
