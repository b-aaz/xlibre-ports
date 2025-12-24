--- module/rdpCapture.c.orig	2025-12-24 08:52:57 UTC
+++ module/rdpCapture.c
@@ -1355,7 +1355,7 @@ copy_vmem(rdpPtr dev, RegionPtr in_reg)
     if (copyGC != NULL)
     {
         tmpval[0].val = GXcopy;
-        ChangeGC(NullClient, copyGC, GCFunction, tmpval);
+        ChangeGC(NULL, copyGC, GCFunction, tmpval);
         ValidateGC(&(hwPixmap->drawable), copyGC);
         count = REGION_NUM_RECTS(in_reg);
         pbox = REGION_RECTS(in_reg);
