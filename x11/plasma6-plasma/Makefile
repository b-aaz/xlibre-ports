PORTNAME=	plasma
DISTVERSION=	${KDE_PLASMA_VERSION}
CATEGORIES=	x11 kde
PKGNAMEPREFIX=	plasma6-

MAINTAINER=	kde@FreeBSD.org
COMMENT=	KDE Plasma 6 (meta port)
WWW=		https://www.kde.org/plasma-desktop

FLAVORS=	xorg xlibre
FLAVOR?=	${FLAVORS:[2]}

USES=		kde:6 metaport qt:6
USE_KDE=	${_USE_PLASMA_ALL:Nplasma-pa}

OPTIONS_DEFINE=		PULSEAUDIO QT5
OPTIONS_DEFAULT=	${OPTIONS_DEFINE}

PULSEAUDIO_USE=		KDE=plasma-pa:run
QT5_DESC=		Install Plasma 6 integration plugins for Qt5 applications
QT5_RUN_DEPENDS=	plasma6-plasma-integration-qt5>0:x11/plasma6-plasma-integration@qt5

BROKEN_DragonFly= BROKEN due to missing dependencies in DPorts

.include <bsd.port.pre.mk>

.if ${FLAVOR} == xlibre
PKGNAMEPREFIX:=		xlibre-${PKGNAMEPREFIX}

# Make the XLibre flavor of this port depend on the XLibre flavor of plasma-desktop
RUN_DEPENDS:=${RUN_DEPENDS:S/plasma-desktop/plasma-desktop@xlibre/}
BUILD_DEPENDS:=${BUILD_DEPENDS:S/plasma-desktop/plasma-desktop@xlibre/}
CONFLICTS=plasma6-plasma-desktop
.else
CONFLICTS=xlibre-plasma6-plasma-desktop
.endif

.include <bsd.port.post.mk>
