PORTNAME=	xlibre-xf86-input-libinput
PORTVERSION=	1.3.0
PORTREVISION=	1
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre libinput input driver
WWW=		https://github.com/X11Libre/xf86-input-libinput/

LICENSE=	MIT # various styles
LICENSE_FILE=	${WRKSRC}/COPYING

CONFLICTS_INSTALL=	xf86-input-libinput

BUILD_DEPENDS=	${LOCALBASE}/include/linux/input.h:devel/evdev-proto
LIB_DEPENDS=	libinput.so:x11/libinput

GH_TAGNAME=	2e1f7a9
USES=		pathfix tar:xz xlibre-cat:driver

GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share

.include <bsd.port.mk>
