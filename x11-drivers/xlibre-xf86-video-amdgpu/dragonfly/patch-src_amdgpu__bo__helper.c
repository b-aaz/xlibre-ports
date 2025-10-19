--- src/amdgpu_bo_helper.c.orig
+++ src/amdgpu_bo_helper.c
@@ -82,13 +82,17 @@ struct amdgpu_buffer *amdgpu_alloc_pixmap_bo(ScrnInfoPtr pScrn, int width,
 		if (usage_hint & AMDGPU_CREATE_PIXMAP_SCANOUT)
 			bo_use |= GBM_BO_USE_SCANOUT;
 
+#ifdef HAVE_GBM_BO_USE_FRONT_RENDERING
 		if (usage_hint & AMDGPU_CREATE_PIXMAP_FRONT)
 			bo_use |= GBM_BO_USE_FRONT_RENDERING;
+#endif
 
+#ifdef HAVE_GBM_BO_USE_LINEAR
 		if (usage_hint == CREATE_PIXMAP_USAGE_SHARED ||
 		    (usage_hint & AMDGPU_CREATE_PIXMAP_LINEAR)) {
 			bo_use |= GBM_BO_USE_LINEAR;
 		}
+#endif
 
 		pixmap_buffer->bo.gbm = gbm_bo_create(info->gbm, width, height,
 						      gbm_format,
