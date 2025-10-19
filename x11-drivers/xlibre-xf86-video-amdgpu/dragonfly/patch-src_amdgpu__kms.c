--- src/amdgpu_kms.c.orig
+++ src/amdgpu_kms.c
@@ -1325,11 +1325,13 @@ static Bool AMDGPUPreInitAccel_KMS(ScrnInfoPtr pScrn)
 	if (xf86ReturnOptValBool(info->Options, OPTION_ACCEL, TRUE)) {
 		AMDGPUEntPtr pAMDGPUEnt = AMDGPUEntPriv(pScrn);
 		Bool use_glamor = TRUE;
+#ifdef HAVE_GBM_BO_USE_LINEAR
 		const char *accel_method;
 
 		accel_method = xf86GetOptValString(info->Options, OPTION_ACCEL_METHOD);
 		if ((accel_method && !strcmp(accel_method, "none")))
 			use_glamor = FALSE;
+#endif
 
 #ifdef DRI2
 		info->dri2.available = ! !xf86LoadSubModule(pScrn, "dri2");
