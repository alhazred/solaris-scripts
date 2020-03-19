#include <stdio.h>
#include <string.h>
#include <unistd.h>

/*
    author: Michael Poetsch
    eMail.: michael.poetsch@hp.com

    mycat -h  displays a comprehensive help screen
    
*/

int showhelp()

  {
   printf("\nmycat * Version 1.01 * 14.03.2003\n");
   printf("=================================\n\n");
   printf("a) mycat <File>\n");
   printf("   Displays <File>\n\n");
   printf("b) mycat -r<ReplChar> <File>\n");
   printf("   Displays <File> and replaces each space char by <ReplChar>.\n"); 
   printf("   This can be useful in shell scripts / loops!\n\n");
   printf("c) mycat -e<EOLString> <File>\n");
   printf("   Displays <File> and adds <EOLString> to the end of each line.\n");
   printf("   This can be useful in shell scripts / loops!\n\n");
   printf("   And all combinations thereof...\n\n");
   printf("d) mycat -h\n");
   printf("   Displays this help screen.\n\n");
   return(0);
  }

main(argc,argv)
int argc;
char *argv[80];
#define ARGS "r:e:h"

{

FILE *eingabe;
FILE *ausgabe;

int LoopCounter=0;
int i,c,Repl = 1;

char Zeile[120];
char InFileName[20];
char dummy;
char in;
char ReplChar = ' ';
char EOLString[] = "+-:-+";


 if (argc < 2)

       {
        printf("usage:");
        printf(" %s [[-r<ReplChar> -e<EOLString>] <File>] | -h \n",argv[0]);
        exit(1);
       }

 optarg = NULL;

 while ((c = getopt(argc,argv,ARGS)) != EOF)
     {
      switch ((char)c)
           {
            case 'r'  : (char)ReplChar = (char)*optarg;
                        break;
            case 'h'  : i = showhelp();
                        exit(i);
                        break;
            case 'e'  : strcpy(EOLString,optarg);
                        Repl = 0;
                        break;
            default   : printf("usage:");
                        printf(" %s [[-r<ReplChar> -e<EOLString>] <File>] | -h\n",argv[0]);
                        exit(2);

           }
     }

 strcpy(InFileName,argv[argc-1]);

 if ( (eingabe = fopen(InFileName,"r")) == NULL) 
           { printf("cannot open %s\n",InFileName);
             exit(1);
           }

 LoopCounter = 0;

 while ( fscanf(eingabe,"%c",&in) != EOF )

           {

            if ( ((char)in == '\n') & (Repl == 0) )
                {
                 printf("%s",EOLString);
                }
           
             if ((char)in == ' ')
                {
                 printf("%c",ReplChar);
                }
             else
                { 
                 printf("%c",in);
                }

           }

 if ( fclose(eingabe) == EOF )
           { 
             printf("cannot close %s\n",InFileName);
             exit(1);
           }

}



/*
 * This script is submitted to BigAdmin by a user of the BigAdmin community.
 * Sun Microsystems, Inc. is not responsible for the
 * contents or the code enclosed. 
 * 
 * 
 * Copyright 2006 Sun Microsystems, Inc. ALL RIGHTS RESERVED
 * Use of this software is authorized pursuant to the
 * terms of the license found at
 * http://www.sun.com/bigadmin/common/berkeley_license.html
 *
 */
 
 



