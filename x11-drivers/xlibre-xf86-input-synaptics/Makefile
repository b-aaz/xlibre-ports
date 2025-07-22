PORTNAME=	xlibre-xf86-input-synaptics
PORTVERSION=	1.9.1
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre synaptics input driver
WWW=		https://github.com/X11Libre/xf86-input-synaptics/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

CONFLICTS_INSTALL=	xf86-input-synaptics

GH_TAGNAME=	42ac305
USES=		pathfix xorg xlibre-cat:driver
USE_XORG=	x11 xtst

GNU_CONFIGURE_MANPREFIX=${PREFIX}/share

OPTIONS_DEFINE=	EVDEV
OPTIONS_DEFAULT_FreeBSD=	EVDEV
OPTIONS_DEFAULT=${OPTIONS_DEFAULT_${OPSYS}}
EVDEV_DESC=	Use evdev for input events (requires kernel support)

EVDEV_CONFIGURE_ENV=	BUILD_EVENTCOMM=yes
EVDEV_BUILD_DEPENDS=	${LOCALBASE}/include/linux/input.h:devel/evdev-proto
EVDEV_LIB_DEPENDS=	libevdev.so:devel/libevdev

.include <bsd.port.mk>
