#!/usr/bin/awk -f
# Disclaimer and Terms: You may use these scripts for commercial or
# non-commercial use at your own risk, as long as you retain the
# copyright statements in the source code. These scripts are provided
# "AS IS" with no warranty whatsoever and are FREE for as long as you
# want to use them. You can edit and adapt them to your requirements
# without seeking permission from me. I only ask that you retain the
# credits where they are due. 
#
# Author: Vishal Goenka <vgoenka@hotmail.com>

# eXtract Source Code Comment
# Version 1.0
#
# Usage: xscc.awk [extract=code|comment|copyright] [prune=copyright]
#                 [blanklines=1] [language=<lang>] file ...
#
# Note:  If your shell environment does not have /usr/bin/awk available
#        you might have to run this command by typing:
# awk -f xscc.awk [extract=code|comment|copyright] [prune=copyright]
#                 [blanklines=1] [language=<lang>] file ...
# Certain old versions of awk may not support this script. If the awk
# on your system gives errors, consider using nawk or gawk.
#
# This AWK script extracts program source code, comments or copyright 
# statements. Copyright statements are defined as the comment lines that
# preceed the first line of code.
#
# The default behavior is to extract the source code, and filter the
# comments out. The optional arguments are described below:
#
#    extract=code      -- print the code, filter comments out. This mode
#                         is the default, unless overridden otherwise.
#    extract=comment   -- print the comments, and filter out the code. 
#    extract=copyright -- print the copyright statements only.
#
#    prune=copyright   -- in the default mode (extract=code), it prints
#                         all code and comments following the copyright 
#                         statements, which are filtered out. 
#                         In the 'extract=comment' mode, it prints all
#                         comments other than the copyright statements.
# 
#    blanklines=1      -- by default, blank lines are not printed, unless 
#                         specified using this option.
#    
#    language=<lang>   -- force a specific language as per the following
#                         table, rather than infer the language from the
#                         extension, which is the default behavior.
#
# This script supports the following programming languages, and infers the 
# language from the file extension (unless overridded using language=<lang>)
# as follows:
#
# Language         Extensions
# Java             java, idl
# C                c
# C++              C, cc, cpp, h, H
# JavaScript       js
# HTML             htm, html
# Shell            sh, ksh, bash, ksh
# Perl             pl, perl, pm
#
func i(b,c,e,d){y=0;z=(e=="copyright");A=z||(e=="comment");B=(!z&&(prune=="copyright"));C=D=E="";if(!b)b=d[split(c,d,".")];else c="";if(b==c)C="#";else if(b~/^(java|C|cc|h|H|cpp|idl|js)$/){C="//";D="/*";E="*/"}else if(b~/^(c)$/){D="/*";E="*/"}else if(b~/^htm|html$/){D="<!--";E="-->"}else C="#"}func f(g){gsub("\\*","\\*",g);return g}func h(a,j){if(z&&!j&&a)nextfile;else if(B&&a){if(A&&!j)B=0;else if(!A&&j){print a;y=1}}else if(j)F=F a}func k(l,t){if(l!~/[\x022\x027]/)return "";else{gsub(/\\.|[^\x022\x027]/,"",l);do{t=l;gsub(/^\x022\x027*\x022|^\x027\x022*\x027/,"",l)}while(t!=l);if(length(l))l=substr(l,0,1);return l}}func p(q,l,n){n=index(l,q);if(n<=1||(n>1&&substr(l,n-1,1)!="\x05c"))return n;else return n+p(q,substr(l,n+1))}func o(l,g,r,n){n=split(l,r,f(g));G=0;h(r[1] g,A);if(n>1)v(substr(l,length(r[1] g)+1))}func s(l,m,g,r,n,q,u){u=length(g)+1;n=split(l,r,f(g));q=k(r[1]);if(!length(q)){if(m){G=1;h(r[1],!A);h(g,A);if(n>1)v(substr(l,length(r[1])+u))}else{h(r[1],!A);h(substr(l,length(r[1])+1),A)}}else{if(n>1){n=p(q,substr(l,length(r[1])+u));if(n)n+=length(r[1])+u-1}if(n>1){h(substr(l,1,n),!A);if(n<length(l))v(substr(l,n+1))}else print l}}func v(l,w,x){if(D){if(G){if(index(l,E))o(l,E);else h(l,A)}else{w=index(l,D);if(C&&(x=index(l,C))&&(!w||x<w))s(l,0,C);else if(w)s(l,1,D);else h(l,!A)}}else{if(index(l,C))s(l,0,C);else h(l,!A)}}{if(FNR==1)i(language,FILENAME,extract);if(y)print;else{F="";v($0);if(blanklines||F~/[^ ]/)print F}}