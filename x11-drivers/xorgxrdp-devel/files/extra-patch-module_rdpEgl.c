--- module/rdpEgl.c.orig	2025-12-24 08:56:45 UTC
+++ module/rdpEgl.c
@@ -735,7 +735,7 @@ rdpEglCaptureRfx(rdpClientCon *clientCon, RegionPtr in
     {
         tmpval[0].val = GXcopy;
         tmpval[1].val = 0;
-        ChangeGC(NullClient, rfxGC, GCFunction | GCForeground, tmpval);
+        ChangeGC(NULL, rfxGC, GCFunction | GCForeground, tmpval);
         ValidateGC(&(screen_pixmap->drawable), rfxGC);
         pixmap = pScreen->CreatePixmap(pScreen, width, height,
                                        pScreen->rootDepth,
