#include <stdlib.h>
#include <unistd.h>

int main ( int argc, char ** argv )
{
	long long s=0;
        if (argc!=2){
                return 1;
        }
	s=strtoll(argv[1],NULL,10);
        if (s==0){
                return 1;
        }
	usleep (s);
	return 0;
}
