PORTNAME=	xlibre-xf86-video-nv
PORTVERSION=	2.1.23.1
PORTREVISION=	1
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre nv display driver
WWW=		https://github.com/X11Libre/xf86-video-nv/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

CONFLICTS_INSTALL=	xf86-video-nv

GH_TAGNAME=	bcdaee5
USES=		tar:xz xlibre-cat:driver

GNU_CONFIGURE_MANPREFIX=${PREFIX}/share

THIS_OPSYS!=	uname -s
.if ${THIS_OPSYS}==DragonFly
CFLAGS+=	-Wno-maybe-uninitialized
.endif
.include <bsd.port.mk>
