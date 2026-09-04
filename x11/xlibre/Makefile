PORTNAME=	xlibre
PORTVERSION=	0.1
CATEGORIES=	x11

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre + X.Org complete distribution metaport
WWW=		https://github.com/X11Libre/ \
		https://www.x.org/

LICENSE=	none

USES=		metaport

RUN_DEPENDS+=	${LOCALBASE}/libdata/pkgconfig/dri.pc:graphics/mesa-libs

# data
RUN_DEPENDS+=	${LOCALBASE}/share/pkgconfig/xbitmaps.pc:x11/xbitmaps \
		${LOCALBASE}/share/icons/handhelds/cursors/X_cursor:x11-themes/xcursor-themes
.if ${:!uname -s!} == DragonFly
RUN_DEPENDS:=${RUN_DEPENDS:S@share/pkgconfig/xbitmaps@libdata/pkgconfig/xbitmaps@}
RUN_DEPENDS:=${RUN_DEPENDS:S@graphics/mesa-libs@graphics/mesa-dri@}
.endif # Temp fixes till DFBSD gets recent FBSD changes.

OPTIONS_DEFINE=	DOCS

DOCS_RUN_DEPENDS+=	${LOCALBASE}/share/doc/xorg-docs/README.xml:x11/xorg-docs

# app, lib, font, driver
RUN_DEPENDS+=	xorg-apps>0:x11/xorg-apps \
		xorg-libraries>0:x11/xorg-libraries \
		xorg-fonts>0:x11-fonts/xorg-fonts \
		xlibre-drivers>0:x11-drivers/xlibre-drivers

.include <bsd.port.mk>
