#!/usr/local/bin/perl
# Script to sum df data
# Written 3/16/99 by Robert G. Ferrell

$| = 1;

@get_df = qx(df -k);

foreach (@get_df) {
	($fs,$kb,$used,$avail,$cap,$mount) = split(/\s+/);
	$kb_tot += $kb unless $fs =~ /^\/vol/;
	$kb_av += $avail unless $fs =~ /^\/vol/;
		if ($fs eq "swap") { $swap_kb = $kb; }
}
$swap_perc = int ($swap_kb / $kb_tot * 100);
$mb_ins = int ($kb_tot / 1000);
$mb_ins_mod = $kb_tot % 1000;
	if ($mb_ins_mod >= 500) { $mb_ins++; }
$mb_av = int ($kb_av / 1000);
$mb_av_mod = $kb_av % 1000;
	if ($mb_ac_mod >= 500) { $mb_av++; }
$mb_sw = int ($swap_kb / 1000);
$mb_sw_mod = $swap_kb % 1000;
if ($mb_sw_mod >= 500) { $mb_sw++; }

print <<"End_of_print";

        Total mounted fixed disk space = $kb_tot KB ($mb_ins MB)
        Total mounted fixed disk space available = $kb_av KB ($mb_av MB)

        You have $swap_kb kb ($mb_sw MB) of swap space allocated, which
        represents $swap_perc% of the total
	
End_of_print
