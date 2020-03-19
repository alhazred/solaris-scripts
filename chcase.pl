eval 'exec perl $0 ${1+"$@"}'
if 0;
# don't modify below here
#-------------------------
$VERSION='2.0';
# chcase 2.0
# Changes case of filenames
# http://www.blemished.net/chcase.html
# supermike@blemished.net
#

use Getopt::Std;
use Cwd;
use File::Basename;

sub HELP_MESSAGE {
print<<EOT;

chcase $VERSION
USAGE:
chcase [-terdlouCcqn] [-x '<perl exp>'] FILE...

       -t       : Test mode (don't actually rename any files)
       -e       : Print examples
       -r       : Rename recursively
       -d       : Also rename directories
       -l       : Rename & follow symbolic links (default is not to)
       -o       : Overwrite if file exists
       -u       : Change to uppercase (default is lower)
       -C       : Capitalize each word
       -c       : Capitalize first character only
       -q       : Quiet mode (no output)
       -n       : No escape characters (for bold/inverse output)
-x '<perl exp>' : Perl expression to operate on filename
                  like s/// or tr///  (you need the quotes)
                  case of filename not changed when this option used

EOT
exit;
}

sub EXAMPLES() {
print<<EOT;

chcase $VERSION
EXAMPLES:
\$ chcase My.DOC *.JPG /tmp/FileName.txt
  => files are changed to lowercase

\$ chcase -rdt .
  => show what would happen if we renamed all files and sub dirs
     recursively in pwd to lowercase; remove t to do it for real

\$ chcase -rdoc /some/dir ./images/ *png
  => files and dirs recursively capitalized,
     overwrite any existing already capitalized file

\$ chcase -x 's/projectx/PlanB/; s/ /_/g' *.doc
  => renames *.doc files substituting "projectx" with "PlanB",
     and replacing all spaces with underscores

\$ find ./music/ -name "*mp3" | xargs chcase -x 'tr/a-zA-Z0-9.-_/_/cs'
  => find mp3 files under music/ dir, transliterate (and squash)
     non-alphanumeric characters except for . or - to _

EOT
exit;
}

sub msg {
 return if $opt_q; my($ol,$new,$err)=@_;
 $out='   'x($lvl-1).$s.$ol; $out.="  =>  $new" if $new;
 $out.=" : $i$err" if $err; print "$out$n\n";
}

sub chcase {
 $_=$old=shift;
 $dn=dirname($_).'/'; $dn="" if ($dn eq './');
 $_=basename($_);
 if ($opt_x) { eval $opt_x; } else { $_=$opt_u ? uc : lc; }
 $_=$dn.$_;
 return($old) if (($old eq $_) or -d or (-f and !$opt_o));
 if ($opt_t or rename($old, $_)) { msg($old,$_); return($opt_t ? $old : $_); }
 else { msg($old,$_,$!); return($old); }
}

sub proc {
 shift;
 if (-l and !$opt_l) { return; }
 if (-f) { chcase($_); }
 elsif (-d) {
   s/\/+$//;
   if ($opt_d) { $_=chcase($_); }
   if ($opt_r) {
     my $cwd=cwd();
     if (chdir($_)) { msg("$b$_/"); } else { msg("$b$_/",0,$!); return; }
     $lvl++; $s='|__';
     opendir(D,'.');
     foreach (readdir(D)) { proc($_) unless (($_ eq '.') or ($_ eq '..')); }
     closedir(D);
     chdir($cwd);
     $s='' if (--$lvl == 0);
   }
 }
}

sub init() {
 $Getopt::Std::STANDARD_HELP_VERSION=true;
 getopts( 'erdouqtnlCcx:' ) or HELP_MESSAGE();
 EXAMPLES() if $opt_e;
 unless ($opt_n) {$b="\033[01m"; $i="\033[03m"; $n="\033[0m"; }
 $opt_x='s/([^_-\s]+)/\u\L$1/g' if $opt_C;
 $opt_x='$_=ucfirst(lc)' if $opt_c;
}

init();
while ($_=shift @ARGV) { proc($_); }
