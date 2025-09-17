--- hw/xfree86/xorg-wrapper.c.orig	2022-11-27 19:45:48.785564000 +0100
+++ hw/xfree86/xorg-wrapper.c	2022-11-27 19:49:05.278882000 +0100
@@ -39,7 +39,7 @@
 #include <sys/sysmacros.h>
 #endif
 #include <sys/types.h>
-#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
+#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__DragonFly__)
 #include <sys/consio.h>
 #endif
 #include <unistd.h>
@@ -170,7 +170,7 @@
     r = fstat(fd, &st);
     if (r == 0 && S_ISCHR(st.st_mode) && major(st.st_rdev) == 4)
       return 1;
-#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
+#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__DragonFly__)
     int idx;
 
     if (ioctl(fd, VT_GETINDEX, &idx) != -1)
