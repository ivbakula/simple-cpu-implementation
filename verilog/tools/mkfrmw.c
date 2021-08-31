#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char unsigned bytes[256];
int  words[64];

int load_binary(char *progpath)
{
	int size = 0;
	FILE *fp = fopen(progpath, "rb");
	if (!fp) {
		fprintf(stderr, "Error! Binary file \"%s\" doesn't exist!", progpath);
		return -1;
	}

	size = fread(words, sizeof(int), 64, fp);
	fclose(fp);
	return size;
}

int load_bytes(char *progpath)
{
	int size = 0;
	FILE *fp = fopen(progpath, "rb");
	if (!fp) {
		fprintf(stderr, "Error! Binary file \"%s\" doesn't exist!", progpath);
		return -1;
	}

	size = fread(bytes, sizeof(char), 256, fp);
	fclose(fp);
	return size;
}

int main(int argc, char *argv[])
{

	if (argc < 2) {
	    fprintf(stderr, "usage: make_firmware <binary_file> \n");
	    exit(-1);
	}

	if (argc > 2 && !strcmp(argv[1], "-s")) {
		const char *str = argv[2];
		for (int i = 0; i < 2250; i = i + 4) {
			if (i < strlen(str))
			    printf("%02x %02x %02x %02x\n", 
				    str[i+3], str[i+2], str[i+1], str[i]);
//			else
//			    printf("00 00 00 00\n");
		}
	} else {
		int size_1 = load_binary(argv[1]);
		int size_2 = load_bytes(argv[1]);

		for (int i = 0; i < 2250; i = i + 4) {
			if (i < size_2)
				printf("%02x %02x %02x %02x\n", 
					bytes[i+3], bytes[i+2], bytes[i+1], bytes[i]);
//			else
//				printf("00 00 00 00\n");
		}
	}
	return 0;

}
