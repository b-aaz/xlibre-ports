PORTNAME=	xlibre-xf86-input-vmmouse
PORTVERSION=	13.2.0.2
PORTREVISION=	1
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre vmmouse input driver
WWW=		https://github.com/X11Libre/xf86-input-vmmouse/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

CONFLICTS_INSTALL=	xf86-input-vmmouse

USES=		gmake xlibre-cat:driver

GH_TAGNAME=	fa6a064

THIS_OPSYS!=	uname -s

.if ${THIS_OPSYS}==DragonFly
AMD64=x86_64
.else
AMD64=amd64
.endif

ONLY_FOR_ARCHS=	${AMD64} i386
ONLY_FOR_ARCHS_REASON=	vmmouse protocol is only supported on x86-compatible architectures

GNU_CONFIGURE_MANPREFIX=${PREFIX}/share

.if ${THIS_OPSYS}==DragonFly
CONFIGURE_ARGS+=	--with-hal-callouts-dir=${PREFIX}/libexec/hal/scripts
PLIST_FILES+=		libexec/hal/scripts/hal-probe-vmmouse
.endif

.include <bsd.port.mk>
