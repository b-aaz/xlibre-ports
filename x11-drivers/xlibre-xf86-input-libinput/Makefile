PORTNAME=	xlibre-xf86-input-libinput
PORTVERSION=	1.3.0
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre libinput input driver
WWW=		https://github.com/X11Libre/

LICENSE=	MIT # various styles
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	${LOCALBASE}/include/linux/input.h:devel/evdev-proto
LIB_DEPENDS=	libinput.so:x11/libinput

GH_TAGNAME=	cda5a98
USES=		pathfix tar:xz xlibre-cat:driver

GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share

.include <bsd.port.mk>
