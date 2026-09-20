#!/bin/sh
set -e

[ "${GITHUB_ACTIONS}" = "true" ] && echo '::group::INNER-CLONE'
mkdir -p "${CI_RUN_DIR:?}"
fetch -o - "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/tarball/$GITHUB_REF" | \
       	tar -xvz --strip-components=1 -C "${CI_RUN_DIR}"
[ "${GITHUB_ACTIONS}" = "true" ] && echo '::endgroup::'


cd "${CI_RUN_DIR}"

. ./.ci/print-utils.sh

mkdir -p "${CI_ART_DIR:?}"

BUILD_START_TIME="$(awk 'BEGIN{srand(); print srand()}')"
OS_NAME="$(uname -s)"
PKG_DIR="${CI_ART_DIR}/${GITHUB_REF_NAME}"
case "${OS_NAME}" in
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
	# Get ports tree's latest commit hash based on branch.
	PORTS_COMMIT_SHA="$(fetch -o -\
	"${GITHUB_SERVER_URL}/${PORTS_REPO}/info/refs?service=git-upload-pack"|\
		grep "${PORTS_BRANCH}$" |\
		cut -c 5- |\
		cut -d' ' -f1 )"

	mkdir -p "$PORTS_DIR"
	rm -rf   "${PORTS_DIR:?}/*"
	fetch -o - \
	"${GITHUB_API_URL}/repos/${PORTS_REPO}/tarball/${PORTS_COMMIT_SHA}"|\
		tar -xz --strip-components=1 -C "${PORTS_DIR}"
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
	echo "OVERLAYS=${CI_RUN_DIR}" | tee    /etc/make.conf
	echo "BATCH=yes"              | tee -a /etc/make.conf
	echo "WITH_CCACHE_BUILD=yes"  | tee -a /etc/make.conf
	echo "CCACHE_DIR=/tmp/ccache/"| tee -a /etc/make.conf
	echo "PACKAGES=${PKG_DIR}"    | tee -a /etc/make.conf
	echo "WITH_DEBUG=yes"         | tee -a /etc/make.conf
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
		xargs pkg install -y
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
		xargs pkg install -y
}
section_end

section STAGE-DBG
{
	make clean stage || exit 1
}
section_end

section STAGE-QA-DBG
{
	make stage-qa || exit 1
}
section_end

section CHECK-PLIST-DBG
{
	make check-plist || exit 1
}
section_end

section PACKAGES-DBG
{
	mkdir -p "${PKG_DIR}"
	make package || exit 1
}
section_end

section REPO-CREATION-DBG
{
	PKG_ABI="$(pkg config abi)"
	REPO_DIR="${PKG_DIR}/${PKG_ABI}"
	mv "${PKG_DIR}/All" "${REPO_DIR}"
	# Retry repo creation ad-infinitum with a timeout until it
	# actually creates a repo.
	# For some weird reason pkg-ng just randomly gets stuck when trying to
	# create a repo on DFBSD, so we have to resort to this abomination.
	# ( I hate pkg-ng :-). )
	while ! timeout -k 15s 10s pkg -dddd repo -o "${REPO_DIR}" "${REPO_DIR}"
	do
		echo Retrying repo creation.
	done
}
section_end

section ARTIFACT-CREATION-DBG
{
	tar -C "${CI_ART_DIR}" -cf "${PKG_DIR%%/}.dbg.tar"\
		"$(basename "${PKG_DIR}")"

	rm -rf "${PKG_DIR}"
	sha256 "${PKG_DIR%%/}.dbg.tar" >"${PKG_DIR%%/}.dbg.tar.sha256"
}
section_end

# Building stripped pkgs,
if [ "${GITHUB_REF_NAME}" != "dev" ] # Only on branches that aren't dev.
then
	section MAKE-RECONFIG
	{
		sed -i.bak '/^WITH_DEBUG=.*/d'     /etc/make.conf
		cat /etc/make.conf
	}
	section STAGE
	{
		make clean stage || exit 1
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
		mkdir -p "${PKG_DIR}"
		make package || exit 1
	}
	section_end

	# Including a fixed version of KDE plasma in release builds.
	if [ "${OS_NAME}" = "FreeBSD" ]
	then
		section KDE-FIX
		{
			./.ci/xlibre-kde-fixer.sh "${PKG_DIR}/All/" || exit 1
		}
		section_end
	fi

	section REPO-CREATION
	{
		PKG_ABI="$(pkg config abi)"
		REPO_DIR="${PKG_DIR}/${PKG_ABI}"
		mv "${PKG_DIR}/All" "${REPO_DIR}"
		while ! timeout -k 15s 10s pkg -dddd repo -o "${REPO_DIR}" "${REPO_DIR}"
		do
			echo Retrying repo creation.
		done
	}
	section_end

	section ARTIFACT-CREATION
	{
		tar -C "${CI_ART_DIR}" -cf "${PKG_DIR%%/}.tar"\
			"$(basename "${PKG_DIR}")"

		rm -rf "${PKG_DIR}"
		sha256 "${PKG_DIR%%/}.dbg.tar" >"${PKG_DIR%%/}.tar.sha256"
	}
	section_end

fi

section BUILD_INFO
{
	printf '+ Operating system: %s\n'	"$(uname -s)" | \
		tee "${CI_ART_DIR}/build_info.md"

	printf '+ Kernel version: %s\n'		"$(uname -K)" | \
		tee -a "${CI_ART_DIR}/build_info.md"

	printf '+ Base version: %s\n'		"$(uname -U)" | \
		tee -a "${CI_ART_DIR}/build_info.md"

	printf '+ Raw build time: %ss\n'\
		"$((
			$(awk 'BEGIN{srand(); print srand()}')-BUILD_START_TIME
			))" | \
		tee -a "${CI_ART_DIR}/build_info.md"

	printf '+ Ports tree repository: %s\n'\
		"https://github.com/${PORTS_REPO}" | \
		tee -a "${CI_ART_DIR}/build_info.md"

	printf '+ Ports tree branch: %s\n'	"${PORTS_BRANCH}" | \
		tee -a "${CI_ART_DIR}/build_info.md"

	printf '+ Ports tree commit: %s\n'	"${PORTS_COMMIT_SHA}" | \
		tee -a "${CI_ART_DIR}/build_info.md"
}
section_end

find "${CI_ART_DIR}/" -type f -name '*.tar' -print -exec tar -tf {} \;
exit 0
