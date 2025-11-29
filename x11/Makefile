    COMMENT = Ports to support the X window system

    THIS_OPSYS!=	uname -s

    SUBDIR += xlibre
    SUBDIR += slim

.if ${THIS_OPSYS}!=DragonFly
    SUBDIR += kde
    SUBDIR += nvidia-driver
    SUBDIR += nvidia-driver-304
    SUBDIR += nvidia-driver-340
    SUBDIR += nvidia-driver-390
    SUBDIR += nvidia-driver-470
    SUBDIR += nvidia-driver-devel
    SUBDIR += plasma6-plasma
    SUBDIR += plasma6-plasma-desktop
.endif

.include <bsd.port.subdir.mk>
