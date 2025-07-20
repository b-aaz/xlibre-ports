PORTNAME=	xlibre-server
PORTVERSION=	${XLIBRE_VER}
PORTREVISION=	1
CATEGORIES=	x11-servers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	Xlibre X server
WWW=		https://github.com/xlibre/xserver

LICENSE=	MIT

CONFLICTS_INSTALL=	xorg-server

USES+=		xlibre-cat:server

# TODO: XLibre server seams to depend on libepoll-shim, it should be added here.

LIB_DEPENDS+=	libudev.so:devel/libudev-devd \
		libxcvt.so:x11/libxcvt \
		libdrm.so:graphics/libdrm \
		libepoxy.so:graphics/libepoxy

MESON_ARGS+=	-Dudev=true \
		-Dudev_kms=true \
		-Dlog_dir=/var/log \
		-Dsuid_wrapper=true
MESON_ARGS+=	-Ddrm=true

PLIST_SUB+=	FONTPATHD="${FONTPATHD:S,^${PREFIX}/,,}"

USE_XORG+=	pciaccess

USE_GL+=	gbm

.include "../xlibre-server/Makefile.common"

OLDMODULEDIR=	/lib/xorg/modules
post-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/X11/xorg.conf.d
	@${MKDIR} ${STAGEDIR}${PREFIX}${OLDMODULEDIR}/extensions
	@${MKDIR} ${STAGEDIR}${PREFIX}${OLDMODULEDIR}/drivers
	@${MKDIR} ${STAGEDIR}${PREFIX}${OLDMODULEDIR}/input
	@${MKDIR} ${STAGEDIR}${FONTPATHD}
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/X11/xorg.conf.d
	@${INSTALL_DATA} ${FILESDIR}/20-evdev-kbd.conf \
		${STAGEDIR}${PREFIX}/share/X11/xorg.conf.d
.include <bsd.port.post.mk>
