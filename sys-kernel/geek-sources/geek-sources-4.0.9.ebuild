# Copyright 2009-2014 Andrey Ovcharov <sudormrfhalt@gmail.com>
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
DEBLOB_AVAILABLE="0"

KMV="$(echo $PV | cut -f 1-2 -d .)"
KSV="$(echo $PV | cut -f 1-3 -d .)"

AUFS_VER="${KMV}"
BFQ_VER="${KMV}.0-v7r8"

# 2015-07-02 : Supports up to 3.19
# URL to check: https://github.com/rmullick/bld-patches
#BLD_VER="${KMV}"

BFS_VER="462"
CK_VER="${KMV}-ck1"
ICE_VER="for-linux-head-${KMV}.0-rc6-2015-04-06"
FEDORA_VER="master"
#GRSEC_VER="3.1-${KMV}.7-201506300712"
#GRSEC_SRC="https://grsecurity.net/test/grsecurity-${GRSEC_VER}.patch"
LQX_VER="${KMV}.9-1"
MAGEIA_VER="releases/${KSV}/1.mga5"
PAX_VER="${KSV}-test22"
PAX_SRC="http://www.grsecurity.net/~paxguy1/pax-linux-${PAX_VER}.patch"
REISER4_VER="4.0.4"
RT_VER="${KMV}.5-rt4"
SUSE_VER="stable"
UKSM_VER="beta"
UKSM_NAME="uksm-0.1.2.4-${UKSM_VER}-for-linux-v${KMV}"

SUPPORTED_USES="aufs bfq bfs brand -build ck -deblob fedora gentoo ice lqx mageia optimize pax pf reiser4 rt suse symlink uksm zen zfs"

inherit geek-sources

HOMEPAGE="https://github.com/init6/init_6/wiki/${PN}"
KEYWORDS="~amd64 ~x86"

DESCRIPTION="Full sources for the Linux kernel including: fedora, grsecurity, mageia and other patches"
