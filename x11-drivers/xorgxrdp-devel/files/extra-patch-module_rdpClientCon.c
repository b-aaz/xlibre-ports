--- module/rdpClientCon.c.orig	2024-12-15 06:13:44 UTC
+++ module/rdpClientCon.c
@@ -1575,12 +1575,21 @@ rdpClientConInit(rdpPtr dev)
         g_chmod_hex(socket_dir, 0x1777);
     }
 
+    // Later versions of the X server removed the global display variable
+    // and replaced it with a getter function
+#ifdef HAS_DIX_GET_DISPLAY_NAME
+    const char *display = dixGetDisplayName(&dev->pScreen);
+    if (display == NULL)
+    {
+        FatalError("rdpClientConInit: Can't get display from DIX layer");
+    }
+#endif
+
     errno = 0;
     i = (int)strtol(display, &endptr, 10);
     if (errno != 0 || display == endptr || *endptr != 0)
     {
-        LLOGLN(0, ("rdpClientConInit: can not run at non-interger display"));
-        return 0;
+        FatalError("rdpClientConInit: can not run at non-integer display");
     }
 
     /* TODO: don't hardcode socket name */
