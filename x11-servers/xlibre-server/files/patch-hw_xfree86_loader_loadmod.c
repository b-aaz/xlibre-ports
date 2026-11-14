From ba1ff7d98f6015538d15332b57c3327e674ece65 Mon Sep 17 00:00:00 2001
From: b-aaz <85005689+b-aaz@users.noreply.github.com>
Date: Mon, 9 Nov 2026 15:12:30 +0000
Subject: [PATCH] xfree86: loader: Fix memory/array bugs in loadmod.

`sizeof` was incorrectly used to get the length of an string in an array
of char pointers (array of strings), which always returns the system's
pointer size (8 on 64bit) instead of the actual string length.
Was fixed by using `strlen` instead.

Additionally the final step that appended the returning array of strings
with another array of strings, also used an incorrect `memcpy` function
to copy the elements.
Was fixed by using an explicit for loop.

And I also replaced the 'length' variables' type's with the proper
`size_t` type instead of `int`, where possible.

Issue and patch from:

https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=299077

Signed-off-by: b-aaz <b-aazbsd@proton.me>
---
 hw/xfree86/loader/loadmod.c | 22 +++++++++++++---------
 1 file changed, 13 insertions(+), 9 deletions(-)

diff --git a/hw/xfree86/loader/loadmod.c b/hw/xfree86/loader/loadmod.c
index 85f97211e..d2368e76e 100644
--- hw/xfree86/loader/loadmod.c
+++ hw/xfree86/loader/loadmod.c
@@ -516,18 +516,20 @@ _LoaderListDir(const char *subdir, const char **patternlist, int *saved_len)
 const char **
 LoaderListDir(const char *subdir, const char **patternlist)
 {
-    int len = 0;
+    size_t len = 0;
     const char **ret = NULL;
-    int subdirlen = strlen(subdir);
-    for (int i = 0; i < sizeof(stdSubdirs) / sizeof(*stdSubdirs); i++) {
-        int prefixsize = sizeof(stdSubdirs[i]);
-        char* dir = malloc(prefixsize + subdirlen);
+    size_t subdirlen = strlen(subdir);
+
+    for (const char **s = stdSubdirs; *s; s++) {
+        size_t prefixsize = strlen(*s);
+        char* dir = malloc(prefixsize + subdirlen + 1);
         if (!dir) {
             free(ret);
             return NULL;
         }
-        memcpy(dir, stdSubdirs[i], prefixsize - 1);
-        memcpy(dir + prefixsize - 1, subdir, subdirlen + 1);
+
+        memcpy(dir, *s, prefixsize);
+        memcpy(dir + prefixsize, subdir, subdirlen + 1);
 
         int sublen = 0;
         const char **subret = _LoaderListDir(dir, patternlist, &sublen);
@@ -536,7 +538,7 @@ LoaderListDir(const char *subdir, const char **patternlist)
             continue;
         }
 
-        int oldlen = len;
+        size_t oldlen = len;
         len += sublen;
         void *tmp = reallocarray(ret, len + 1, sizeof(*ret));
         if (!tmp) {
@@ -545,7 +547,9 @@ LoaderListDir(const char *subdir, const char **patternlist)
         }
 
         ret = tmp;
-        memcpy(ret + oldlen, subret, sublen);
+        for (size_t i = 0; i < sublen; i++) {
+            ret[oldlen + i] = subret[i];
+	}
     }
     if (ret) {
         ret[len] = NULL;
-- 
2.54.0

