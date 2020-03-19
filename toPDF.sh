#!/bin/sh

### Script that creates a PDF file from a PS file with
### all the fonts embedded.
###
### Used 'ghostscript'
###
### Apostolos Syropoulos
### apostolo@ocean1.ee.duth.gr
###

if [ -z $1 ] ; then
  echo "Usage: toPDF PS"
  echo " where \"PS\" is the name of a PS file "
  echo " with/without the \".ps\" extension"
else
  infile="$1";
  case "${infile}" in
    *.eps)  base=`basename "${infile}" .eps`; outfile="${base}.pdf" ;;
     *.ps)  base=`basename "${infile}" .ps`; outfile="${base}.pdf" ;;
        *)  base=`basename "${infile}"`; infile="$infile.ps" ;
            outfile="${base}.pdf" ;;
  esac
  gs -dSAFER -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -q -sPAPERSIZE=a4 \
  -dPDFSETTINGS=/printer -dCompatibilityLevel=1.3 -dMaxSubsetPct=100 \
  -dSubsetFonts=true -dEmbedAllFonts=true -sOutputFile="${outfile}" "${infile}"
fi










##############################################################################
### This script is submitted to BigAdmin by a user of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed. 
###
###
### Copyright 2006 Sun Microsystems, Inc. ALL RIGHTS RESERVED
### Use of this software is authorized pursuant to the
### terms of the license found at
### http://www.sun.com/bigadmin/common/berkeley_license.html
##############################################################################


