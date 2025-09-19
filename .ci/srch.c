#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>

/* Had to write my own utility for this ... . */

/* This program reads the input unbuffered byte by byte and compares it against
 * the string given as the first argument.
 * As soon as a match is found it will exit with status code 0 and if no
 * matches are found till EOF, it will exit with status code 1 */

/* This program is useful for monitoring live logfiles piped by tail -f and 
 * waiting till a string is found.
 * grep Does not work in this scenario because it is line based and buffered,
 * It also does not ignore SIGPIPE and this can return the infamous 141
 * error. */

/* For example grep fails to detect a string when it is in a line that has not
 * yet terminated by a newline in tail -f output. */

int main(int argc, char ** argv) {

    char *search_string = argv[1];
    size_t search_string_len = strlen(search_string);
    size_t idx = 0;
    char c;

    if (argc != 2) {
        return 2;
    }

    signal(SIGPIPE,SIG_IGN);
    while (read(STDIN_FILENO, &c, 1) > 0) {
        if (c == search_string[idx]) {
            idx++;
            if (idx == search_string_len) {
		    exit(0);
            }
        } else {
            idx = (c == search_string[0]) ? 1 : 0;
        }
    }
    exit(1);
}
