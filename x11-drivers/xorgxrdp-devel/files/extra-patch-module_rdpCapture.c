--- module/rdpCapture.c.orig	2026-04-22 13:33:42 UTC
+++ module/rdpCapture.c
@@ -757,7 +757,7 @@ rdpCopyBoxList(rdpClientCon *clientCon, PixmapPtr dstP
         return FALSE;
     }
     tmpval[0].val = GXcopy;
-    ChangeGC(NullClient, copyGC, GCFunction, tmpval);
+    ChangeGC(NULL, copyGC, GCFunction, tmpval);
     ValidateGC(&(hwPixmap->drawable), copyGC);
     count = num_out_rects;
     pbox = out_rects;
