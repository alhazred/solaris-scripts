#!/usr/bin/perl -lan

##
##
######################################################################
## Just a nothing script that counts the recurrence of letters from stdin.
## Written 000630 -Ed Arizona
##
## usage: cat /text-file | ./crap.pl
##
## Questions or problems?  UnixAdmin@ArizonaEd.com
## Visit the unix archive at http://www.arizonaed.com/unix
## Check out the long list of links, http://www.arizonaed.com/unix/urls.html
##
## Please feel free to email me about possible job opportunities in
## the NY/NJ/PA area.
##
######################################################################

for ($i=0; $i<=length($_); $i++)
 {
  $hash{lc(substr($_,$i,1))}++
 }

END {
foreach $key (sort keys %hash)
{
  printf "%d: %s\n",$hash{$key},$key;
}

###
#  show all keys at end
###
##foreach $key (sort keys %hash)
##{
##  printf "%s",$key;
##}
##print;print;

}
