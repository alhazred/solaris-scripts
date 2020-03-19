/* patchlist.c - 05/06/2003 */
/* Here a little filter in C to make a sorted table */
/*  of the patches installed on the system. */
/*  */
/* usage:  showrev -p|sort|patchlist */


main()
{
  char line[1024];
  char patchnum[10];
  char prev[10];
  char rev[4];

  strcpy(prev,"");
  while (gets(line)) {
    strncpy(patchnum,line+7, 6);
    patchnum[6]='\0';
    strncpy(rev,line+14, 2);
    rev[2]='\0';
    if (strcmp(patchnum, prev)!=0) {
      printf("\n%s: %s", patchnum, rev);
    }
    else {
      printf(" %s", rev);
    }
    strcpy(prev, patchnum);
  }
  printf("\n");
}


/*
 * This script is submitted to BigAdmin by a user of the BigAdmin community.
 * Sun Microsystems, Inc. is not responsible for the
 * contents or the code enclosed. 
 * 
 * 
 * Copyright 2005 Sun Microsystems, Inc. ALL RIGHTS RESERVED
 * Use of this software is authorized pursuant to the
 * terms of the license found at
 * http://www.sun.com/bigadmin/common/berkeley_license.html
 *
 */


