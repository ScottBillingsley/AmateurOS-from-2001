/*
	Binary to Hex converter and dump...
	Scott Billingsley	6/26/2001

*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/stat.h>
#include <graphics.h>
#include <conio.h>
#include <math.h>

/*Function prototype*/
int bin2hex(char *infile,char *outfile,char *buffer);

void main()
{
int i;
char infile[255], outfile[255],buffer[8];

for(i=1;i<26;i++)printf("\n");
gotoxy(1,1);
printf("               Binary to HEX converter\n");
printf("               Scott Billingsley 6/26/2001\n");
printf("	       using Borland C++ v3.1\n\n\n");

printf("Input file name		:");
scanf("%s",&infile);
printf("\nOutput file name	:");
scanf("%s",&outfile);
gotoxy(1,12);
printf("Working..");
bin2hex(infile,outfile,buffer);
}

int bin2hex(char *in,char *out, char *buffer)
{
FILE *infile, *outfile;
int ch,cnt,csum,ofsa,x;
char lead='0';
char mid='X';
char last=',';
char lf='\n';
char start[6]="$ DB \0";
char header1[]="// HEX Binary to HEX converter \n// by  Scott Billingsley \n\0";
char header2[80]="\0";
char headerFirst[]="// Input file :";
char headerSecond[]="  Output file :";
struct stat statbuf;
long int fsize,fpoint,fsub,adrs;

/*Prepare header*/
strcat(header2,headerFirst);
strcat(header2,in);
strcat(header2,headerSecond);
strcat(header2,out);
strcat(header2,"\n\n\0");
/*Open file check*/
if((infile = fopen(in, "rb")) ==NULL){
	printf("Cannot open input file.\n");
	return 1;
}
printf("\n%s opened..\n",in);
if((outfile = fopen(out, "wt")) ==NULL){
	printf("Cannot open output file.\n");
	return 1;
}
printf("%s opened..\n",out);
fstat(fileno(infile), &statbuf);
printf("Input file size=%ld\n",statbuf.st_size);
fsize=statbuf.st_size;

fprintf(outfile,"%s",header1);
fprintf(outfile,"%s",header2);

for(fsub=1;fsub<fsize+1;fsub++){
	if(fsub==1){
		fprintf(outfile,"%s",start);
		}
	ch=fgetc(infile);
	fprintf(outfile,"%c",lead);
	fprintf(outfile,"%c",mid);
	fprintf(outfile,"%02X",ch);
		if(fmod(fsub,8)==0 ){
		fprintf(outfile,"%c",lf);
		fprintf(outfile,"%s",start);
		}
	else{
		if(fsub<fsize){
			fprintf(outfile,"%c",last);
			}
		}

}


fclose(infile);
fclose(outfile);

}





