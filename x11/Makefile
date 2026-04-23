    COMMENT = Ports to support the X window system

    THIS_OPSYS!=	uname -s

.if ${THIS_OPSYS}!=DragonFly
    SUBDIR += plasma6-plasma-desktop
.endif

    SUBDIR += xlibre
    SUBDIR += xlibre-minimal

.include <bsd.port.subdir.mk>
