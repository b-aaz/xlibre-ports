--- src/radeon_kms.c.orig
+++ src/radeon_kms.c
@@ -58,6 +58,10 @@
 #include <X11/extensions/dpms.h>
 #endif
 
+#ifdef __DragonFly__
+#include <xf86_OSproc.h>
+#endif
+
 #include <X11/extensions/damageproto.h>
 
 #include "radeon_chipinfo_gen.h"
@@ -1527,6 +1531,24 @@ static int radeon_get_drm_master_fd(ScrnInfoPtr pScrn)
     XNFasprintf(&busid, "pci:%04x:%02x:%02x.%d",
                 dev->domain, dev->bus, dev->dev, dev->func);
 
+#ifdef __DragonFly__
+    /* On DragonFlyBSD Appropriate kernel drivers need to be loaded before
+     * accessing DRM facilities */
+    int loaded=0; /* if we were able to load the module. */
+    loaded = xf86LoadKernelModule("radeon");
+    /* EEXIST is set if the module has already been loaded in the kernel */
+    if (!loaded && errno != EEXIST) {
+    	loaded = xf86LoadKernelModule("radeonkms");
+    	if (!loaded && errno != EEXIST) {
+		xf86DrvMsg(pScrn->scrnIndex, X_ERROR,
+		   "[drm] Failed to load kernel module for %s: %s\n",
+		   busid, strerror(errno));
+		free(busid);
+		return -1;
+    	}
+    }
+#endif
+
     fd = drmOpen(NULL, busid);
     if (fd == -1)
 	xf86DrvMsg(pScrn->scrnIndex, X_ERROR,
