PORTNAME=	xlibre-xf86-video-ast
PORTVERSION=	25.0.0
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre ASPEED display driver
WWW=		https://github.com/X11Libre/xf86-video-ast/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

USES=		xlibre-cat:driver
INSTALL_TARGET=	install-strip

PLIST_FILES=	${MODULEDIR}/drivers/ast_drv.so

THIS_OPSYS!=	uname -s

.if ${THIS_OPSYS}==DragonFly
CFLAGS+=	-Wno-maybe-uninitialized
ONLY_FOR_ARCHS=	i386 x86_64
.else
ONLY_FOR_ARCHS=	amd64 i386
.endif

.include <bsd.port.mk>
