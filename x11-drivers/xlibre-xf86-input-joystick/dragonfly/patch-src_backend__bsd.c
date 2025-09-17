--- src/backend_bsd.c.orig
+++ src/backend_bsd.c
@@ -42,13 +42,20 @@
 #include <xf86_OSproc.h>
 
 #include <usbhid.h>
-#include <dev/usb/usb.h>
-#include <dev/usb/usbhid.h>
-#ifdef HAVE_DEV_HID_HID_H
-    #include <dev/hid/hid.h>
-#endif
-#ifdef HAVE_DEV_USB_USB_IOCTL_H
-    #include <dev/usb/usb_ioctl.h>
+
+#ifndef __DragonFly__
+# include <dev/usb/usb.h>
+# include <dev/usb/usbhid.h>
+# ifdef HAVE_DEV_HID_HID_H
+#  include <dev/hid/hid.h>
+# endif
+# ifdef HAVE_DEV_USB_USB_IOCTL_H
+#  include <dev/usb/usb_ioctl.h>
+# endif
+#else
+# include <bus/u4b/usb.h>
+# include <bus/u4b/usbhid.h>
+# include <bus/u4b/usb_ioctl.h>
 #endif
 
 #include "jstk.h"
