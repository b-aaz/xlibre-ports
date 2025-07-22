PORTNAME=	xlibre-xf86-input-vmmouse
PORTVERSION=	13.1.0
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre vmmouse input driver
WWW=		https://github.com/X11Libre/xf86-input-vmmouse/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

CONFLICTS_INSTALL=	xf86-input-vmmouse

GH_TAGNAME=	f27f2b1
USES=		gmake xlibre-cat:driver

ONLY_FOR_ARCHS=	amd64 i386
ONLY_FOR_ARCHS_REASON=	vmmouse protocol is only supported on x86-compatible architectures

GNU_CONFIGURE_MANPREFIX=${PREFIX}/share

.include <bsd.port.mk>
