# Porting X11Libre to FreeBSD [![Build Status](https://api.cirrus-ci.com/github/b-aaz/xlibre-ports.svg)](https://cirrus-ci.com/github/b-aaz/xlibre-ports)

## An effort for porting [X11Libre](https://github.com/X11Libre) to FreeBSD.



---
## Installing the packages from sources:

You need the ports tree installed to build these packages.

```sh
git clone https://b-aaz/xlibre-ports/
cd xlibre-ports/
echo "OVERLAYS=$(pwd)/" >> /etc/make.conf
make clean
make install
```
---
## Installing the binary packages from build artifacts:
Binary packages are available from the CI builds.
To add them as a `pkg` repository you can do the following:
```sh
su

cat > /usr/local/etc/pkg/repos/XLibre.conf <<\EOF
XLibre: {
        url: "https://api.cirrus-ci.com/v1/artifact/github/b-aaz/xlibre-ports/pkgs/pkgs/pkgs/${ABI}",
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
Be aware that these packages are still in beta stage, both the ports and the upstream sources.
They:
* may not work as expected
* may overwrite files
* make unicorns come out of your nose
* or anything in between.

So, please make sure that you understand what you are doing.  
It is recommended that you have _some_ `ports` and `pkg` knowledge before installing these.  
I also suggest running and building these in a jail, VM or test machine not your main box.
