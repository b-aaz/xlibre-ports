# Porting XLibre to FreeBSD and DragonFlyBSD! [![Build Status](https://api.cirrus-ci.com/github/b-aaz/xlibre-ports.svg)](https://cirrus-ci.com/github/b-aaz/xlibre-ports)

## An effort for porting [XLibre](https://github.com/X11Libre) to FreeBSD and DragonFlyBSD.


---
## Installing the packages from sources:

Firstly, make sure that you have the FreeBSD ports tree is installed and fully populated in `/usr/ports`.
[FreeBSD Handbook - Installing the Ports Collection](https://docs.freebsd.org/en/books/handbook/ports/#ports-using-installation-methods).

Then, clone this tree, enable it as an overlay, and clean everything just to be sure:
```sh
git clone https://github.com/b-aaz/xlibre-ports.git
cd xlibre-ports/
echo "OVERLAYS=$(pwd)/" >> /etc/make.conf
make clean
```

Finaly, to build and install a port, move to its directory and run `make install`. For example installing xlibre-server would be as follows:
```sh
cd x11-servers/xlibre-server
make install
```
---
## Installing the binary packages from build artifacts:
Binary packages are available from the CI builds.
To add them as a `pkg` repository you can do the following on both FreeBSD and
DragonFlyBSD:

```sh
su

cat > /usr/local/etc/pkg/repos/XLibre.conf <<\'EOF'
XLibre: {
        url: "https://api.cirrus-ci.com/v1/artifact/github/b-aaz/xlibre-ports/bins/bins/${ABI}",
        mirror_type: "http",
        enabled: yes
}
EOF
```

Then you can install the packages as you would any other package.

```sh
su
pkg install xlibre-server xlibre-drivers
```
__Note__: The CI artifacts binary packages are built with debugging flags set and
they also have full debug symbols included and are built with -O0 optimization. 
This is to ease debugging in case of problems.

## Video drivers

Installing the video card drivers should be followed as instructed in the
 [FreeBSD handbook]( https://docs.freebsd.org/en/books/handbook/x11/#x-graphic-card-drivers ).



It is recommended that you have _some_ `ports` and `pkg` knowledge before
installing these ports.  
