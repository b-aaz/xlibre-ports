#!/bin/sh
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
	char=$1
	count=$2
	while [ $count -gt 0 ];
	do
		printf '%s' "$char"
		count=$(( $count - 1 ))
	done
}
center() {
	string=$1
	string_len=${#string}
	pad_len=$2
	pad_r_len=$(( ($pad_len - $string_len)/2 + ($pad_len - $string_len)%2 ))
	pad_l_len=$(( ($pad_len - $string_len)/2 ))

	repeat_string ' ' $pad_r_len 
	printf '%s' "$string"
	repeat_string ' ' $pad_l_len
}

section() {
	text_color=6
	border_color=3
	on_github && echo "::group::$1"
	tput setaf $border_color
	echo '/============================================================================\'
	printf '%s' "|"
	tput setaf $text_color
	center "$1" 76
	tput setaf $border_color
	printf '%s\n' "|"
	echo '\============================================================================/'
	tput setaf 9

}
section_end() {
	text_color=6
	border_color=3
	on_github && echo "::endgroup::"
	tput setaf $border_color
	printf '%s' '\================================+'
	tput setaf $text_color
	printf '%s' 'END-SECTION'
	tput setaf $border_color
	printf '%s\n' '+===============================/'
	tput setaf 9
}

not_defined(){
	var_name=$1
	var_value=$(eval 'echo "$'$var_name'"')
	[ -z "$var_value" ]
}
export_not_defined(){
	var_name=$1
	value=$2
	not_defined "$var_name" && export "$var_name"="$value"
}

env_setup(){

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
		on_github && echo "::group::$title" &&
		tput setaf $border_color &&
		printf '%s' '>>>>>>>>>>>>>>' &&
		tput setaf $text_color &&
		echo "$title" &&
		tput setaf 9
	}
}

debug_ci_end(){
	text_color=6
	border_color=1
	[ "$DEBUG_CI" = "YES" ] &&
	{
		on_github && echo "::endgroup::"
		tput setaf $border_color
		echo '<<<<<<<<<<<<<<'
		tput setaf $text_color
		echo "END-DEBUG-SECTION"
		tput setaf 9
	}
}

step_0(){
	section 'Clone and checkout'
	git clone "$REPO_URL"
	git switch "$BRANCH"

	debug_ci && {
		ls .
		debug_ci_end
	}

	section_end
}
step_1(){
	section 'Perquisites'
	ASSUME_ALWAYS_YES=yes pkg bootstrap -f
	pkg install -y git-lite
	section_end
}

step_2(){
	section 'Ports tree setup'
	ls ${PORTS_DIR}

	if [ ! -f "${PORTS_DIR}/${PORTS_BRANCH}" ]
	then
		mkdir -p ${PORTS_DIR} &&
			fetch "${PORTS_REPO_URL}/archive/refs/heads/${PORTS_BRANCH}.tar.gz" -o - | tar xf - -C ${PORTS_DIR} --strip-components=1 &&
			touch "${PORTS_DIR}/${PORTS_BRANCH}"
	fi
	debug_ci && {
		ls "${PORTS_DIR}"
		debug_ci_end
	}
	section_end
}

step_3(){
	section 'ccache setup'
	pkg install -y ccache-static
	ccache --max-size=${CCACHE_SIZE}
	section_end
}

step_4(){
	section 'Patch setup'
{
{
patch -N ${PORTS_DIR}/Mk/bsd.port.subdir.mk << EOF
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
	debug_ci && {
		grep -n '^TARGETS+=' ${PORTS_DIR}/Mk/bsd.port.subdir.mk
		debug_ci_end
	}

	section_end
}

step_5(){
	section 'make.conf setup'
	echo 'OVERLAYS=/'"$(pwd)"'/' >> /etc/make.conf
	echo 'WITH_DEBUG=yes' >> /etc/make.conf
	echo 'DEBUG_FLAGS+= -O0' >> /etc/make.conf
	echo "WITH_CCACHE_BUILD=yes" >> /etc/make.conf
	debug_ci && {
		cat /etc/make.conf
		debug_ci_end
	}
	section_end
}

step_6(){
	section 'Install run dependencies'
	make run-depends-list | sort | uniq | grep -v '^==\|xlibre' | cut -d '/' -f 4- | xargs pkg install -y
	section_end
}

step_7(){
	section 'Install build dependencies'
	make build-depends-list | sort | uniq | grep -v '^==\|xlibre\|xorg-macros' | cut -d '/' -f 4- | xargs pkg install -y
	make -C "${PORTS_DIR}/devel/xorg-macros/" clean
	section_end
}

step_8(){
	section 'Stage'
	make stage
	section_end
}

step_9(){
	section 'Stage QA'
	make stage-qa
	section_end
}

step_10(){
	section 'Check-plist'
	make check-plist
	section_end
}

step_10(){
	section 'Package'
	export PACKAGES="$(pwd)/pkgs/"
	mkdir "$PACKAGES"
	make package
	debug_ci && {
		ls "${PACKAGES}"
		debug_ci_end
	}
	section_end
}

step_11(){
	section 'Repo setup'
	ABI="$(pkg config abi)"
	mv "$PACKAGES/All" "$PACKAGES/$ABI"
	pkg repo -l "$PACKAGES/$ABI"
	pkg install -y tree
	cd "$PACKAGES/$ABI"
	tree -h -D -C -H -./ --houtro=/dev/null -T "XLibre binaries for $OS_NAME" ./ > ./index.html
	debug_ci && {
		pwd
		tree
		debug_ci_end
	}
	section_end
}

{
	export DEBUG_CI="YES"

	env_setup

	if [ -n "$1" ] 
	then
		eval "step_$1"
	else
		for i in $(seq 0 11)
		do
			eval "step_$i" || exit
		done
	fi

}
