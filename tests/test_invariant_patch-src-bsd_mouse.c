#include <check.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* Test that shell metacharacters in device paths are properly sanitized
 * before being passed to shell commands. This simulates the vulnerable
 * sprintf pattern from the patch file. */

static int contains_unescaped_shell_metachar(const char *cmd, const char *dev) {
    /* Check if dangerous shell metacharacters from dev appear unescaped in cmd */
    const char *metacharacters = ";|&$`(){}[]<>!\\'\"\n";
    for (const char *p = dev; *p; p++) {
        if (strchr(metacharacters, *p) != NULL) {
            /* Check if this metachar appears unescaped in the command */
            if (strstr(cmd, dev) != NULL) {
                return 1; /* Unsanitized injection possible */
            }
        }
    }
    return 0;
}

START_TEST(test_device_path_shell_injection)
{
    /* Invariant: Shell commands must never include unsanitized user input */
    const char *payloads[] = {
        "/dev/input/mouse0; rm -rf /",  /* Command injection via semicolon */
        "/dev/input/$(whoami)",          /* Command substitution */
        "/dev/input/`id`",               /* Backtick command substitution */
        "/dev/input/mouse0"              /* Valid input - should work */
    };
    int num_payloads = sizeof(payloads) / sizeof(payloads[0]);

    for (int i = 0; i < num_payloads; i++) {
        char cmd[256];
        const char *dev = payloads[i];
        
        /* Simulate the vulnerable sprintf pattern from patch-src-bsd_mouse.c */
        sprintf(cmd, "sh -c 'fstat %s | grep -c moused' 2>/dev/null", dev);
        
        /* For payloads with metacharacters, they must be sanitized */
        int has_metachar = (strchr(dev, ';') || strchr(dev, '$') || 
                           strchr(dev, '`') || strchr(dev, '|'));
        
        if (has_metachar) {
            /* If input has shell metacharacters, they must not appear raw in cmd */
            ck_assert_msg(!contains_unescaped_shell_metachar(cmd, dev),
                "Shell metacharacters in device path '%s' were not sanitized", dev);
        }
    }
}
END_TEST

Suite *security_suite(void)
{
    Suite *s;
    TCase *tc_core;

    s = suite_create("Security");
    tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_device_path_shell_injection);
    suite_add_tcase(s, tc_core);

    return s;
}

int main(void)
{
    int number_failed;
    Suite *s;
    SRunner *sr;

    s = security_suite();
    sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}