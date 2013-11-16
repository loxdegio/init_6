# Copyright 2011-2014 Andrey Ovcharov <sudormrfhalt@gmail.com>
# Distributed under the terms of the GNU General Public License v3
# $Header: $

# @ECLASS: geek-squeue.eclass
# @MAINTAINER:
# Andrey Ovcharov <sudormrfhalt@gmail.com>
# @AUTHOR:
# Original author: Andrey Ovcharov <sudormrfhalt@gmail.com> (12 Aug 2013)
# @BLURB: Eclass for building kernel with squeue patchset.
# @DESCRIPTION:
# This eclass provides functionality and default ebuild variables for building
# kernel with squeue patches easily.

# The latest version of this software can be obtained here:
# https://github.com/init6/init_6/blob/master/eclass/geek-squeue.eclass
# Bugs: https://github.com/init6/init_6/issues
# Wiki: https://github.com/init6/init_6/wiki/geek-sources

inherit geek-patch geek-vars

EXPORT_FUNCTIONS src_unpack src_prepare pkg_postinst

# @FUNCTION: init_variables
# @INTERNAL
# @DESCRIPTION:
# Internal function initializing all variables.
# We define it in function scope so user can define
# all the variables before and after inherit.
geek-squeue_init_variables() {
	debug-print-function ${FUNCNAME} "$@"

	: ${SQUEUE_VER:=${SQUEUE_VER:-"${KMV}"}}
	: ${SQUEUE_SRC:=${SQUEUE_SRC:-"git://git.kernel.org/pub/scm/linux/kernel/git/stable/stable-queue.git"}}
	: ${SQUEUE_URL:=${SQUEUE_URL:-"http://git.kernel.org/cgit/linux/kernel/git/stable/stable-queue.git"}}
	: ${SQUEUE_INF:=${SQUEUE_INF:-"${YELLOW}Stable-queue patch-set -${GREEN} ${SQUEUE_URL}${NORMAL}"}}
	local skip_squeue_cfg=$(source $cfg_file 2>/dev/null; echo ${skip_squeue})
	: ${skip_squeue:=${skip_squeue_cfg:-no}} # skip_squeue=yes/no
}

geek-squeue_init_variables

HOMEPAGE="${HOMEPAGE} ${SQUEUE_URL}"

DEPEND="${DEPEND}
	dev-vcs/git"

# @FUNCTION: src_unpack
# @USAGE:
# @DESCRIPTION: Extract source packages and do any necessary patching or fixes.
geek-squeue_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	local CSD="${GEEK_STORE_DIR}/squeue"
	local CWD="${T}/squeue"

	if [ -d ${CSD} ]; then
		cd ${CSD} || die "${RED}cd ${CSD} failed${NORMAL}"
		git pull > /dev/null 2>&1
	else
		git clone ${SQUEUE_SRC} ${CSD} > /dev/null 2>&1
	fi

	if [ -d ${CSD}/queue-${SQUEUE_VER} ] ; then
		copy "${CSD}/queue-${SQUEUE_VER}" "${CWD}" > /dev/null 2>&1;
		mv "${CWD}/series" "${CWD}/patch_list" > /dev/null 2>&1;
	elif [ -d ${CSD}/releases/${PV} ]; then
		copy "${CSD}/releases/${PV}" "${CWD}" > /dev/null 2>&1;
		mv "${CWD}/series" "${CWD}/patch_list" > /dev/null 2>&1 || ewarn "There is no stable-queue patch-set this time"; skip_squeue="yes";
	else
		ewarn "There is no stable-queue patch-set this time"
		skip_squeue="yes";
	fi
}

# @FUNCTION: src_prepare
# @USAGE:
# @DESCRIPTION: Prepare source packages and do any necessary patching or fixes.
geek-squeue_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

	if [ "${skip_squeue}" = "yes" ]; then
			ewarn "${RED}Skipping update to latest stable queue ...${NORMAL}"
		else
			ApplyPatch "${T}/squeue/patch_list" "${SQUEUE_INF}"
			move "${T}/squeue" "${WORKDIR}/linux-${KV_FULL}-patches/squeue"
	fi
}

# @FUNCTION: pkg_postinst
# @USAGE:
# @DESCRIPTION: Called after image is installed to ${ROOT}
geek-squeue_pkg_postinst() {
	debug-print-function ${FUNCNAME} "$@"

	einfo "${SQUEUE_INF}"
}
