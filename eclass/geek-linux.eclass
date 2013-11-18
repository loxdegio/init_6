# Copyright 2011-2014 Andrey Ovcharov <sudormrfhalt@gmail.com>
# Distributed under the terms of the GNU General Public License v3
# $Header: $

# @ECLASS: geek-linux.eclass
# @MAINTAINER:
# Andrey Ovcharov <sudormrfhalt@gmail.com>
# @AUTHOR:
# Original author: Andrey Ovcharov <sudormrfhalt@gmail.com> (09 Jan 2013)
# @BLURB: Eclass for building linux kernel.
# @DESCRIPTION:
# This eclass provides functionality and default ebuild variables for building
# linux kernel.

# The latest version of this software can be obtained here:
# https://github.com/init6/init_6/blob/master/eclass/geek-linux.eclass
# Bugs: https://github.com/init6/init_6/issues
# Wiki: https://github.com/init6/init_6/wiki/geek-sources

inherit geek-build geek-deblob geek-patch geek-utils geek-vars

EXPORT_FUNCTIONS src_unpack src_prepare src_compile src_install pkg_postinst

# No need to run scanelf/strip on kernel sources/headers (bug #134453).
RESTRICT="mirror binchecks strip"

LICENSE="GPL-2"

# 0 for 3.4.0
if [ "${SUBLEVEL}" = "0" ] || [ "${PV}" = "${KMV}" ] ; then
	PV="${KMV}" # default PV=3.4.0 new PV=3.4
	if [[ "${PR}" == "r0" ]] ; then
		SKIP_UPDATE=1 # Skip update to latest upstream
	fi
fi

# ebuild default values setup settings
EXTRAVERSION=${EXTRAVERSION:-"-geek"}
KV_FULL="${PVR}${EXTRAVERSION}"
S="${WORKDIR}"/linux-"${KV_FULL}"

DEPEND="!build? ( sys-apps/sed
		  >=sys-devel/binutils-2.11.90.0.31 )"
RDEPEND="!build? ( >=sys-libs/ncurses-5.2
		   sys-devel/make
		   dev-lang/perl
		   sys-devel/bc )"
PDEPEND="!build? ( virtual/dev-manager )"

SLOT=${SLOT:-${KMV}}
IUSE="${IUSE} symlink"

case "$PR" in
	r0)	case "$VERSION" in
		2)	extension="xz"
			kurl="mirror://kernel/linux/kernel/v${KMV}/longterm/v${KMV}.${SUBLEVEL}"
			kversion="${KMV}.${SUBLEVEL}"
			if [ "${SUBLEVEL}" != "0" ] || [ "${PV}" != "${KMV}" ]; then
				pversion="${PV}"
				pname="patch-${pversion}.${extension}"
				SRC_URI="${SRC_URI} ${kurl}/${pname}"
			fi
		;;
		3)	extension="xz"
			kurl="mirror://kernel/linux/kernel/v${VERSION}.0"
			kversion="${KMV}"
			if [ "${SUBLEVEL}" != "0" ] || [ "${PV}" != "${KMV}" ]; then
				pversion="${PV}"
				pname="patch-${pversion}.${extension}"
				SRC_URI="${SRC_URI} ${kurl}/${pname}"
			fi
		;;
		esac
	;;
	*)	extension="xz"
		kurl="mirror://kernel/linux/kernel/v${VERSION}.0/testing"
		kversion="${VERSION}.$((${PATCHLEVEL} - 1))"
		if [ "${SUBLEVEL}" != "0" ] || [ "${PV}" != "${KMV}" ]; then
			pversion="${PVR//r/rc}"
			pname="patch-${pversion}.${extension}"
			SRC_URI="${SRC_URI} ${kurl}/${pname}"
		fi
	;;
esac

case "$VERSION" in
	2)	kurl="mirror://kernel/linux/kernel/v${KMV}" ;;
esac

kname="linux-${kversion}.tar.${extension}"
SRC_URI="${SRC_URI} ${kurl}/${kname}"

# @FUNCTION: init_variables
# @INTERNAL
# @DESCRIPTION:
# Internal function initializing all variables.
# We define it in function scope so user can define
# all the variables before and after inherit.
geek-linux_init_variables() {
	debug-print-function ${FUNCNAME} "$@"

	local disable_NUMA_cfg=$(source $cfg_file 2>/dev/null; echo ${disable_NUMA})
	: ${disable_NUMA:=${disable_NUMA_cfg:-yes}} # disable_NUMA=yes/no

	local enable_1k_HZ_ticks_cfg=$(source $cfg_file 2>/dev/null; echo ${enable_1k_HZ_ticks})
	: ${enable_1k_HZ_ticks:=${enable_1k_HZ_ticks_cfg:-yes}} # enable_1k_HZ_ticks=yes/no

	local enable_BFQ_cfg=$(source $cfg_file 2>/dev/null; echo ${enable_BFQ})
	: ${enable_BFQ:=${enable_BFQ_cfg:-no}} # enable_BFQ=yes/no

	local rm_unneeded_arch_cfg=$(source $cfg_file 2>/dev/null; echo ${rm_unneeded_arch})
	: ${rm_unneeded_arch:=${rm_unneeded_arch_cfg:-no}} # rm_unneeded-arch=yes/no
}

geek-linux_init_variables

# @FUNCTION: src_unpack
# @USAGE:
# @DESCRIPTION: Extract source packages and do any necessary patching or fixes.
geek-linux_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	if [ "${A}" != "" ]; then
		ebegin "Extract the sources"
			tar xvJf "${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/${kname}" &>/dev/null
		eend $?
		cd "${WORKDIR}" || die "${RED}cd ${WORKDIR} failed${NORMAL}"
		mv "linux-${kversion}" "${S}" || die "${RED}mv linux-${kversion} ${S} failed${NORMAL}"
	fi
	cd "${S}" || die "${RED}cd ${S} failed${NORMAL}"
	if [ "${SKIP_UPDATE}" = "1" ] ; then
		ewarn "${RED}Skipping update to latest upstream ...${NORMAL}"
	else
		ApplyPatch "${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/${pname}" "${YELLOW}Update to latest upstream ...${NORMAL}"
	fi

	if use deblob; then
		geek-deblob_src_unpack
	fi
}

# @FUNCTION: src_prepare
# @USAGE:
# @DESCRIPTION: Prepare source packages and do any necessary patching or fixes.
geek-linux_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

	ebegin "Set extraversion in Makefile" # manually set extraversion
		sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile
	eend

	get_config

	ebegin "Cleanup backups after patching"
		rm_crap
	eend

	case "$disable_NUMA" in
	yes)	ebegin "Disabling NUMA from kernel config"
			disable_NUMA
		eend ;;
	no)	ewarn "Skipping disabling NUMA from kernel config ..." ;;
	esac

	case "$enable_1k_HZ_ticks" in
	yes)	ebegin "Set tick rate to 1k"
			set_1k_HZ_ticks
		eend ;;
	no)	ewarn "Skipping set tick rate to 1k ..." ;;
	esac

	case "$enable_BFQ" in
	yes)	ebegin "Set BFQ as default I/O scheduler"
			set_BFQ
		eend ;;
	no)	ewarn "Skipping set BFQ as default I/O scheduler ..." ;;
	esac

	case "$rm_unneeded_arch" in
	yes)	ebegin "Remove unneeded architectures"
			if use x86 || use amd64; then
				rm -rf "${WORKDIR}"/linux-"${KV_FULL}"/arch/{alpha,arc,arm,arm26,arm64,avr32,blackfin,c6x,cris,frv,h8300,hexagon,ia64,m32r,m68k,m68knommu,metag,mips,microblaze,mn10300,openrisc,parisc,powerpc,ppc,s390,score,sh,sh64,sparc,sparc64,tile,unicore32,um,v850,xtensa}
				sed -i 's/include/#include/g' "${WORKDIR}"/linux-"${KV_FULL}"/fs/hostfs/Makefile
			else
				rm -rf "${WORKDIR}"/linux-"${KV_FULL}"/arch/{avr32,blackfin,c6x,cris,frv,h8300,hexagon,m32r,m68k,m68knommu,microblaze,mn10300,openrisc,score,tile,unicore32,um,v850,xtensa}
			fi
		eend ;;
	no)	ewarn "Skipping remove unneeded architectures ..." ;;
	esac

	ebegin "Compile ${RED}gen_init_cpio${NORMAL}"
		make -C "${WORKDIR}"/linux-"${KV_FULL}"/usr/ gen_init_cpio > /dev/null 2>&1
		chmod +x "${WORKDIR}"/linux-"${KV_FULL}"/usr/gen_init_cpio "${WORKDIR}"/linux-"${KV_FULL}"/scripts/gen_initramfs_list.sh > /dev/null 2>&1
	eend

	cd "${WORKDIR}"/linux-"${KV_FULL}" || die "${RED}cd ${WORKDIR}/linux-${KV_FULL} failed${NORMAL}"
	local GENTOOARCH="${ARCH}"
	unset ARCH
	ebegin "Running ${RED}make oldconfig${NORMAL}"
		make oldconfig </dev/null &>/dev/null
	eend $? "Failed oldconfig"
	ebegin "Running ${RED}modules_prepare${NORMAL}"
		make modules_prepare &>/dev/null
	eend $? "Failed ${RED}modules prepare${NORMAL}"
	ARCH="${GENTOOARCH}"

	echo
	einfo "${RED}Live long and prosper.${NORMAL}"
	echo
}

# @FUNCTION: src_compile
# @USAGE:
# @DESCRIPTION: Configure and build the package.
geek-linux_src_compile() {
	debug-print-function ${FUNCNAME} "$@"

	if use deblob; then
		geek-deblob_src_compile
	fi
}

# @FUNCTION: src_install
# @USAGE:
# @DESCRIPTION: Install a package to ${D}
geek-linux_src_install() {
	debug-print-function ${FUNCNAME} "$@"

	if use build; then
		geek-build_src_compile
	fi

	local version_h_name="usr/src/linux-${KV_FULL}/include/linux"
	local version_h="${ROOT}${version_h_name}"

	if [ -f "${version_h}" ]; then
		einfo "Discarding previously installed version.h to avoid collisions"
		addwrite "/${version_h_name}"
		rm -f "${version_h}"
	fi

	cd "${S}" || die "${RED}cd ${S} failed${NORMAL}"
	dodir /usr/src
	echo ">>> Copying sources ..."

	move "${WORKDIR}/linux-${KV_FULL}" "${D}/usr/src/linux-${KV_FULL}"
	move "${WORKDIR}/linux-${KV_FULL}-patches" "${D}/usr/src/linux-${KV_FULL}-patches"

	if use symlink; then
		if [ -h "/usr/src/linux" ]; then
			addwrite "/usr/src/linux"
			unlink "/usr/src/linux" || die "${RED}unlink /usr/src/linux failed${NORMAL}"
		elif [ -d "/usr/src/linux" ]; then
			move "/usr/src/linux" "/usr/src/linux-old"
		fi
		dosym linux-${KV_FULL} \
			"/usr/src/linux" ||
			die "${RED}cannot install kernel symlink${NORMAL}"
	fi
}

# @FUNCTION: pkg_postinst
# @USAGE:
# @DESCRIPTION: Called after image is installed to ${ROOT}
geek-linux_pkg_postinst() {
	debug-print-function ${FUNCNAME} "$@"

	einfo " ${BLUE}If you are upgrading from a previous kernel, you may be interested${NORMAL}${BR}
 ${BLUE}in the following document:${NORMAL}${BR}
 ${BLUE}- General upgrade guide:${NORMAL} ${RED}http://www.gentoo.org/doc/en/kernel-upgrade.xml${NORMAL}${BR}
 ${RED}${CATEGORY}/${PN}${NORMAL} ${BLUE}is UNSUPPORTED Gentoo Security.${NORMAL}${BR}
 ${BLUE}This means that it is likely to be vulnerable to recent security issues.${NORMAL}${BR}
 ${BLUE}For specific information on why this kernel is unsupported, please read:${NORMAL}${BR}
 ${RED}http://www.gentoo.org/proj/en/security/kernel.xml${NORMAL}${BR}
 ${BR}
 ${BLUE}Now is the time to configure and build the kernel.${NORMAL}${BR}"

	if use deblob; then
		geek-deblob_pkg_postinst
	fi
}
