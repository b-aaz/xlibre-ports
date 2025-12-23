PORTNAME=	xlibre-xf86-input-evdev
PORTVERSION=	25.0.0
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre event device input driver
WWW=		https://github.com/X11Libre/xf86-input-evdev/

LICENSE=	MIT # various styles
LICENSE_FILE=	${WRKSRC}/COPYING

USES=		pathfix xlibre-cat:driver

BUILD_DEPENDS=	${LOCALBASE}/include/linux/input.h:devel/evdev-proto
LIB_DEPENDS=	libevdev.so:devel/libevdev \
		libmtdev.so:devel/libmtdev
THIS_OPSYS!=	uname -s
.if ${THIS_OPSYS}!=DragonFly
RUN_DEPENDS=	webcamd>=3.1.0.1:multimedia/webcamd
.endif

CONFIGURE_ENV=	UDEV_CFLAGS=" " UDEV_LIBS=" "

.include <bsd.port.mk>
