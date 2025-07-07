# Originally from xorg.mk
#
# Feature:		xlibre
# Usage:		USES=xlibre
# 			USE_XLIBRE=<component>
#
# 			Not specifying USE_XLIBRE with USES=xlibre is an error.
#			
#			Components can be found in the XORG_MODULES list below.
#
#
# If you feel something is missing from the list, please let us know.
#
# MAINTAINER:	x11@FreeBSD.org

.if !defined(_INCLUDE_USES_XLIBRE_MK)
_INCLUDE_USES_XLIBRE_MK=		yes
_USES_POST+=	xlibre
.endif

# Set up things after bsd.port.post.mk.
# This way ports can add things to USE_XLIBRE even after bsd.port.pre.mk is
# included.
.if defined(_POSTMKINCLUDED) && !defined(_INCLUDE_USES_XLIBRE_POST_MK)
_INCLUDE_USES_XLIBRE_POST_MK=	yes

.  if !empty(xlibre_ARGS)
IGNORE=		USES=xlibre takes no arguments
.  endif

.  if !defined(USE_XLIBRE)
IGNORE=		need to specify xlibre modules with USE_XLIBRE
.  endif

# List of xlibre modules
XORG_MODULES=	xlibre-server

# Register all xlibre .pc files here.
# foo_LIB_PC_DEPENDS means it should go to BUILD_DEPENDS *and* RUN_DEPENDS.
xlibre-server_LIB_PC_DEPENDS=	${LOCALBASE}/libdata/pkgconfig/xorg-server.pc:x11-servers/xlibre-server

# Add explicit X options to avoid problems with false positives in configure
.  if defined(GNU_CONFIGURE)
CONFIGURE_ARGS+=--x-libraries=${LOCALBASE}/lib --x-includes=${LOCALBASE}/include
.  endif

.  for _module in ${USE_XLIBRE:M*\:both:C/\:.*//g}
.    if ${XORG_MODULES:M${_module}} == ""
IGNORE=		requires unknown xlibre module (${_module})
.    endif
RUN_DEPENDS+=	${${_module}_BUILD_DEPENDS}
.  endfor

.  for _module in ${USE_XLIBRE:C/\:both$//g}
.    if ${XORG_MODULES:M${_module}} == ""
IGNORE=		requires unknown xlibre module (${_module})
.    endif
LIB_PC_DEPENDS+=${${_module}_LIB_PC_DEPENDS}
BUILD_DEPENDS+=	${${_module}_BUILD_DEPENDS}
.  endfor

RUN_DEPENDS+=	${LIB_PC_DEPENDS}
BUILD_DEPENDS+=	${LIB_PC_DEPENDS}

.endif
