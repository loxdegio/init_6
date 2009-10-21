# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit gnustep-2 subversion

S="${WORKDIR}/Etoile-${PV}/Services/Private/Idle"

DESCRIPTION="sends user-idle notifications every minute that the user is idle"
HOMEPAGE="http://www.etoile-project.org"
SRC_URI=""

ESVN_REPO_URI="svn://svn.gna.org/svn/etoile/stable"
ESVN_PROJECT="etoile"

LICENSE="BSD"
KEYWORDS="~amd64 ~ppc ~x86"
SLOT="0"
IUSE=""

DEPEND="x11-libs/libXScrnSaver"
RDEPEND="${DEPEND}"
