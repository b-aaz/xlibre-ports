--- src/radeon_probe.c.orig
+++ src/radeon_probe.c
@@ -55,7 +55,7 @@
 #include "dri.h"
 #endif
 
-#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
+#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__DragonFly__)
 #include <xf86_OSproc.h>
 #endif
 
@@ -101,7 +101,7 @@ static Bool radeon_kernel_mode_enabled(ScrnInfoPtr pScrn, struct pci_device *pci
 
     busIdString = DRICreatePCIBusID(pci_dev);
     ret = drmCheckModesettingSupported(busIdString);
-#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
+#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__DragonFly__)
     if (ret) {
       if (xf86LoadKernelModule("radeonkms"))
         ret = drmCheckModesettingSupported(busIdString);
