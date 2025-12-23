--- src/amdgpu_probe.c.orig	2025-12-23 20:17:36 UTC
+++ src/amdgpu_probe.c
@@ -92,7 +92,7 @@ static Bool amdgpu_kernel_mode_enabled(ScrnInfoPtr pSc
 	int ret = drmCheckModesettingSupported(busIdString);
 
 	if (ret) {
-		if (xf86LoadKernelModule("amdgpukms"))
+		if (xf86LoadKernelModule("amdgpu"))
 			ret = drmCheckModesettingSupported(busIdString);
 	}
 	if (ret) {
