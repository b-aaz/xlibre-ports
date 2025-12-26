    COMMENT = Ports to support the X window system

    THIS_OPSYS!=	uname -s

.if ${THIS_OPSYS}!=DragonFly
    SUBDIR += plasma6-plasma-desktop
    SUBDIR += nvidia-driver
    SUBDIR += nvidia-driver-304
    SUBDIR += nvidia-driver-340
    SUBDIR += nvidia-driver-390
    SUBDIR += nvidia-driver-470
    SUBDIR += nvidia-driver-devel
.endif


    SUBDIR += slim
    SUBDIR += xlibre
    SUBDIR += xlibre-minimal

.include <bsd.port.subdir.mk>
