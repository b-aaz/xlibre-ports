#!/bin/sh

set_fg_color(){
	[ "$1" -le 9 ] && [ "$1" -gt 0 ] && printf "%s" "[0;3$1m"
	[ "$1" -eq 9 ] && printf "%s" "[0m"
	true
}
	
on_github() {
[ "${GITHUB_ACTIONS}" = "true" ]
}
on_cirrus() {
[ "${CIRRUS_CI}" = "true" ]
}
on_bare() {
	   ! on_github && ! on_cirrus 
}

repeat_string() {
	char="$1"
	count="$2"
	while [ "$count" -gt 0 ];
	do
		printf '%s' "$char"
		count=$(( "$count" - 1 ))
	done
}
center() {
	string="$1"
	string_len=${#string}
	pad_len="$2"
	pad_r_len=$(( (pad_len - string_len)/2 + (pad_len - string_len)%2 ))
	pad_l_len=$(( (pad_len - string_len)/2 ))

	repeat_string ' ' "$pad_r_len" 
	printf '%s' "$string"
	repeat_string ' ' "$pad_l_len"
}

section() {
	text_color=6
	border_color=3
	on_github && echo "::group::$1"
	set_fg_color "$border_color"
	echo '/============================================================================\'
	set_fg_color "$border_color"
	printf '%s' "|"
	set_fg_color "$text_color"
	center "$1" 76
	set_fg_color "$border_color"
	printf '%s\n' "|"
	set_fg_color "$border_color"
	echo '\============================================================================/'
	set_fg_color 9

}
section_end() {
	text_color=6
	border_color=3
	set_fg_color "$border_color"
	printf '%s' '\================================+'
	set_fg_color "$text_color"
	printf '%s' 'END-SECTION'
	set_fg_color "$border_color"
	printf '%s\n' '+===============================/'
	set_fg_color 9
}

not_defined(){
	var_name="$1"
	var_value=$(eval 'echo "$'"$var_name"'"')
	[ -z "$var_value" ]
}
export_not_defined(){
	var_name="$1"
	value="$2"
	not_defined "$var_name" && export "$var_name"="$value"
}

env_setup(){
	# Forcing color
	export FORCE_COLOR="1"
	export CLICOLOR_FORCE="1"
	export CLANG_FORCE_COLOR_DIAGNOSTICS="1"

	export_not_defined OS_NAME "$(uname -s)"

	if not_defined BRANCH
	then
		on_cirrus && export BRANCH="$CIRRUS_BRANCH"
		on_github && export BRANCH="$GITHUB_REF_NAME"
		on_bare && export BRANCH="master"
	fi

	if not_defined PORTS_DIR
	then
		if [ "$OS_NAME" = "DragonFly" ]
		then
			export PORTS_DIR="/usr/dports"
		else
			export PORTS_DIR="/usr/ports"
		fi
	fi

	if not_defined REPO_URL
	then
		on_cirrus && export REPO_URL="$CIRRUS_REPO_CLONE_URL"
		on_github && export REPO_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY.git"
		on_bare && export REPO_URL="https://github.com/b-aaz/xlibre-ports"
	fi

	if not_defined PORTS_REPO_URL
	then
		if [ "$OS_NAME" = "DragonFly" ]
		then
			export PORTS_REPO_URL="https://github.com/dragonflybsd/dports"
		else
			export PORTS_REPO_URL="https://github.com/freebsd/freebsd-ports"
		fi
	fi

	export_not_defined PORTS_BRANCH "master"
	export_not_defined CCACHE_SIZE "200M"
	export_not_defined CCACHE_DIR "/tmp/.ccache"
	export_not_defined CCACHE_COMPRESS 1
	export_not_defined CCACHE_STATIC_PREFIX "/usr/local"
	export_not_defined CCACHE_NOSTATS 1
	export_not_defined CCACHE_TEMPDIR "/tmp"
	export_not_defined WITH_CCACHE_BUILD "YES"

	export_not_defined DEBUG_CI "NO"

	export PACKAGES="/tmp/pkgs/"

	debug_ci && {
		env
		debug_ci_end
	}
}

debug_ci(){
	text_color=6
	border_color=1
	title="DEBUG-SECTION"
	[ -n "$1" ] && title="$1"
	[ "$DEBUG_CI" = "YES" ] &&
	{
		on_github && echo "::group::$title"
		set_fg_color "$border_color"
		printf '%s' '>>>>>>>>>>>>>>'
		set_fg_color "$text_color" 
		echo "$title"
		set_fg_color 9
	}
}

debug_ci_end(){
	text_color=6
	border_color=1
	[ "$DEBUG_CI" = "YES" ] &&
	{
		set_fg_color "$border_color"
		printf '%s' '<<<<<<<<<<<<<<'
		set_fg_color "$text_color"
		echo "END-DEBUG-SECTION"
		set_fg_color 9
		on_github && echo "::endgroup::"
	}
	true
}

step_0(){
	section 'Perquisites'
	ASSUME_ALWAYS_YES=yes pkg bootstrap -f
	pkg install -y git-lite pkg tree zstd
	section_end
}

step_1(){
	section 'Clone and checkout'

	if [ ! -d './.git' ]
	then
		git clone "$REPO_URL" ./  || exit 1
	else
		echo Already cloned
	fi
	
	if [ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ] 
	then
		git switch "$BRANCH" || exit 1
	else
		echo Already switched
	fi

	section_end

	debug_ci && {
		ls .
		debug_ci_end
	}
}

step_2(){
	debug_ci && {
		echo
		echo  "${PORTS_DIR}"
		echo
		ls -la "${PORTS_DIR}"
		echo
		git -C "${PORTS_DIR}" rev-parse --abbrev-ref HEAD
		echo

		debug_ci_end
	}

	section 'Ports tree setup'

	if [ -d "${PORTS_DIR}/.git" ]
	then
		date
		echo "There is a git repo present in the cache"
		branch=$(git -C "${PORTS_DIR}" rev-parse --abbrev-ref HEAD)
		if [ "$PORTS_BRANCH"!="$branch" ]
		then
			date
			echo "There branch names are not equal deleting everything and re-cloning"
			rm -rf "${PORTS_DIR}"
			mkdir -p "${PORTS_DIR}"
			git clone -b "${PORTS_BRANCH}" --single-branch --depth 1 "${PORTS_REPO_URL}" "${PORTS_DIR}"
		else
			date
			echo "The branch names are equal fetching the latest commits if any"
			git -C "${PORTS_DIR}" fetch --depth 1
			git -C "${PORTS_DIR}" reset --hard "origin/$PORTS_BRANCH"
			git -C "${PORTS_DIR}" clean -dfx
		fi
	else
		date
		rm -rf "${PORTS_DIR}"
		mkdir -p "${PORTS_DIR}"
		git clone -b "${PORTS_BRANCH}" --single-branch --depth 1 "${PORTS_REPO_URL}" "${PORTS_DIR}"
	fi
	date

	section_end

	debug_ci && {
		echo
		ls "${PORTS_DIR}"
		echo
		debug_ci_end
	}
}

step_3(){
	section 'ccache setup'
	pkg install -y ccache-static || exit 1
	ccache --max-size="${CCACHE_SIZE}" || exit 1
	section_end
}

step_4(){
	section 'Patch setup'
	{
		{
			patch -N "${PORTS_DIR}/Mk/bsd.port.subdir.mk" <<-"EOF"
			@@ -173,6 +173,11 @@
			 TARGETS+=	realinstall
			 TARGETS+=	reinstall
			 TARGETS+=	tags
			+TARGETS+=	stage
			+TARGETS+=	stage-qa
			+TARGETS+=	check-plist
			+TARGETS+=	run-depends-list
			+TARGETS+=	build-depends-list

			 .for __target in ${TARGETS}
			 .  if !target(${__target})
			EOF
		} || true
	}

	section_end
	
	debug_ci && {
		grep -n '^TARGETS+=' "${PORTS_DIR}/Mk/bsd.port.subdir.mk"
		debug_ci_end
	}
}

step_5(){
	section 'make.conf setup'
	echo 'OVERLAYS=/'"$(pwd)"'/' >> /etc/make.conf
	echo 'BATCH=yes' >> /etc/make.conf
	echo "WITH_CCACHE_BUILD=yes" >> /etc/make.conf
	if [ -n "$SET_PREFIX_PATH" ]
	then
	      echo "PREFIX=$PREFIXP" >> /etc/make.conf
	fi
	section_end

	debug_ci && {
		cat /etc/make.conf
		debug_ci_end
	}
}

step_6(){
	section 'Install run dependencies'
	make run-depends-list | sort | uniq | grep -v '^==\|xlibre' | awk -F "/" '{print $(NF-1) "/" $NF}' | grep -v 'x11-drivers/xf86-video-scfb\|x11/plasma6-plasma$\|x11/plasma6-plasma-desktop' | xargs pkg install -y || exit 1
	[ "$OS_NAME" != "DragonFly" ] &&  pkg install -y nvidia-kmod
	
	section_end
}

step_7(){
	section 'Install build dependencies'
	make build-depends-list | sort | uniq | grep -v '^==\|xlibre\|xorg-macros' | awk -F "/" '{print $(NF-1) "/" $NF}' | grep -v 'x11/plasma6-plasma-desktop' | xargs pkg install -y || exit 1
	make -C "${PORTS_DIR}/devel/xorg-macros/" clean || exit 1
	section_end
}

step_8(){
	section 'Stage'
	make stage || exit 1
	section_end
}

step_9(){
	section 'Stage QA'
	make stage-qa || exit 1
	section_end
}

step_10(){
	section 'Check-plist'
	make check-plist || exit 1
	section_end
}

step_11(){
	section 'Package'
	mkdir "$PACKAGES"
	make package || exit 1
	section_end

	debug_ci && {
		tree "${PACKAGES}"
		debug_ci_end
	}
}

step_12(){
	section 'Repo setup'
	ABI="$(pkg config abi)"

	rm -rf ./* ./.*

	mv "$PACKAGES/All" "./$ABI"
	cd "./$ABI" || exit 1

	# Retry repo creation on DFBSD ad-infinitum with a timeout until it
	# actually creates a repo.
	# For some weird reason pkg just randomly gets stuck when trying to
	# create a repo on DFBSB.
	# ( I hate pkg-ng :-). )
	if [ "$OS_NAME" == "DragonFly" ]
	then
		while ! timeout -k 15s 10s pkg -dddddd repo .
		do
			echo Retrying the repo creation
		done
	else
		pkg repo . || exit 1
	fi

	if [ -n "$SET_PREFIX_PATH" ]
	then
		binorset="sets"
	else
		binorset="binaries"
	fi
	title_msg="XLibre $binorset for $OS_NAME $(echo "$ABI" | cut -d: -f 2- | tr ':' ' ')"
	tree -h -D -C -H -./ --houtro=/dev/null -T "$title_msg" ./ > ./index.html
	section_end

	debug_ci && {
		pwd
		tree
		debug_ci_end
	}
}

{
	export DEBUG_CI="YES"

	env_setup

	if [ -n "$1" ] 
	then
		eval "step_$1"
	else
		for i in $(seq 0 12)
		do
			eval "step_$i" 
		done
		exit 0
	fi

}
