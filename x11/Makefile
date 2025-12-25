    COMMENT = Ports to support the X window system

    THIS_OPSYS!=	uname -s

    SUBDIR += slim
    SUBDIR += xlibre
    SUBDIR += xlibre-minimal

.if ${THIS_OPSYS}!=DragonFly
    SUBDIR += nvidia-driver
    SUBDIR += nvidia-driver-304
    SUBDIR += nvidia-driver-340
    SUBDIR += nvidia-driver-390
    SUBDIR += nvidia-driver-470
    SUBDIR += nvidia-driver-devel
    SUBDIR += plasma6-plasma-desktop
.endif

.include <bsd.port.subdir.mk>
