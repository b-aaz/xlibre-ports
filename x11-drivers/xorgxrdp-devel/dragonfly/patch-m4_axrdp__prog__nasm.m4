--- m4/axrdp_prog_nasm.m4.orig	2026-04-23 22:48:39 UTC
+++ m4/axrdp_prog_nasm.m4
@@ -40,7 +40,7 @@ case "$host_os" in
         ;;
     esac
   ;;
-  kfreebsd* | freebsd* | netbsd* | openbsd*)
+  kfreebsd* | freebsd* | netbsd* | openbsd* | dragonfly*)
     if echo __ELF__ | $CC -E - | grep __ELF__ > /dev/null; then
       objfmt='BSD-a.out'
     else
