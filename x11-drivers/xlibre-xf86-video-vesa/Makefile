PORTNAME=	xlibre-xf86-video-vesa
PORTVERSION=	25.0.0
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre vesa display driver
WWW=		https://githhub.com/X11Libre/xf86-video-vesa

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

USES=		xlibre-cat:driver

THIS_OPSYS!=	uname -s

.if ${THIS_OPSYS}==DragonFly
ONLY_FOR_ARCHS=	i386 x86_64
.else
ONLY_FOR_ARCHS=	amd64 i386
.endif

.include <bsd.port.mk>
