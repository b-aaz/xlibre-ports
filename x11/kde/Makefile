PORTNAME=	kde
PORTVERSION=	${KDE_PLASMA_VERSION}.${KDE_APPLICATIONS_VERSION}
CATEGORIES=	x11 kde

MAINTAINER=	kde@FreeBSD.org
COMMENT=	KDE Plasma Desktop and Applications (meta port)
WWW=		https://www.kde.org

FLAVORS=	xorg xlibre
FLAVOR?=	${FLAVORS:[2]}

RUN_DEPENDS=	kde-baseapps>=${KDE_APPLICATIONS_VERSION}:x11/kde-baseapps

.if ${FLAVOR} == xlibre
PKGNAMEPREFIX:=		xlibre-
RUN_DEPENDS=	xlibre-plasma6-plasma>=${KDE_PLASMA_VERSION}:x11/plasma6-plasma@xlibre
CONFLICTS=	plasma6-plasma
.else
RUN_DEPENDS=	plasma6-plasma>=${KDE_PLASMA_VERSION}:x11/plasma6-plasma
CONFLICTS=	xlibre-plasma6-plasma
.endif


USES=		kde:6 metaport qt:6

# The official VLC backend can be used, but vlc port still uses Qt5 for GUI.
OPTIONS_DEFAULT=	MPV
OPTIONS_MULTI=	PHONON
OPTIONS_MULTI_PHONON=	MPV VLC

PHONON_DESC=	Phonon multimedia backend

MPV_DESC=	mpv backend
MPV_USE=	KDE=phonon-mpv

VLC_DESC=	VLC backend (depends on Qt5 packages)
VLC_USE=	KDE=phonon-vlc

BROKEN_DragonFly= BROKEN due to missing dependencies in DPorts

.include <bsd.port.mk>
