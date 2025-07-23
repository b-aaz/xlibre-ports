PORTNAME=	xlibre-xf86-video-intel
DISTVERSION=	2.99.917-923
CATEGORIES=	x11-drivers

MAINTAINER=	b-aazbsd@proton.me
COMMENT=	XLibre legacy driver for Intel integrated graphics chipsets
WWW=		https://01.org/linuxgraphics/xf86-video-intel/

LICENSE=	MIT	# various
LICENSE_FILE=	${WRKSRC}/COPYING

ONLY_FOR_ARCHS=	amd64 i386
ONLY_FOR_ARCHS_REASON=	only Intel integrated GPUs on x86 are supported

LIB_DEPENDS=	libdrm_intel.so:graphics/libdrm

CONFLICTS_INSTALL=	xf86-video-intel

USES=		localbase xlibre xlibre-cat:driver
GH_TAGNAME=	5245636
USE_XORG=	pciaccess pixman
GNU_CONFIGURE_MANPREFIX=${PREFIX}/share
CONFIGURE_ENV=	ac_cv_header_sys_sysinfo_h=no # XXX ports/242236
CONFIGURE_ARGS=	--with-builderstring="${DISTVERSIONFULL}"
TEST_TARGET=	check

# XXX bug 214593: SNA crashes on pre-SandyBridge hardware
CONFIGURE_ARGS+=--with-default-accel=uxa

OPTIONS_DEFINE=	UDEV XVMC TOOLS
OPTIONS_DEFAULT=UDEV XVMC
OPTIONS_SUB=	yes

TOOLS_DESC=		Enables misc tools
TOOLS_USE=		XORG=x11,xcb,xinerama,xrandr,xdamage,xcursor,xtst,xfixes,xrender,xscrnsaver,xext
TOOLS_LIB_DEPENDS+=	libxshmfence.so:x11/libxshmfence
TOOLS_CONFIGURE_ENABLE=	tools

UDEV_DESC=		udev-based monitor hotplug detection
UDEV_LIB_DEPENDS=	libudev.so:devel/libudev-devd
UDEV_CONFIGURE_ENABLE=	udev

XVMC_LIB_DEPENDS=	libxcb-util.so:x11/xcb-util libXvMC.so:x11/libXvMC
XVMC_USE=		XORG=x11,xcb,xvmc
XVMC_CONFIGURE_ENABLE=	xvmc
XVMC_VARS=		USE_LDCONFIG=yes


post-patch:
.if ${CONFIGURE_ARGS:M--with-default-accel=uxa}
	@${REINPLACE_CMD} '/^Default/s/SNA/UXA/' ${WRKSRC}/man/intel.man
.endif

.include <bsd.port.mk>
