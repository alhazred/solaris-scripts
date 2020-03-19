#!/usr/local/bin/perl
# Script to convert seconds-since-epoch to current date
# Written 11/28/97 by Robert G. Ferrell
# Revised 1/12/98  RGF
# Caveat: There's a bug in the conversion algorithm somewhere. 

$sse = $ARGV[0];
$days = 0;
$hours = 0;
$mins = 0;
$secs = 0;
$year = 0;
$month = "";

if ($sse eq "-v") {
  print "This is sec2date, version 1.1, 1/12/98\n";
  exit;
}

unless ($sse) { 
  print "Usage: sec2date \[seconds\]\n";
  exit;
  }

&days;
&year;
&month;
&date;
&weekday;
&hours;
&mins;
&secs;
&print;

sub days {

$day_r = $sse / 86400;
  if ($day_r < 1) {
    $day_i = 0;
  } else { 
    $day_i = int ($day_r);
  }
$days = $day_i;
}

sub year {

    if ($days <= 789) { $leap = 0; 
    } elsif ($days <= 2249) { $leap = 1;
    } else {
        $leap = int ((($days - 2250) / 1460) + 1);
    }
    $years_r = ($day_r - $leap) / 365 ;
    $years_i = int ($years_r);  
    $year = $years_i + 1970;
        if ($year % 4 == 0) {
            $leap_n = 1;
        } else { $leap_n = 0; 
        }       
}

sub month {

   $months_r = $years_r - $years_i;
   $months_l = $months_r * 12;
   $months_i = int ($months_l);
     if ($months_i == 0) { 
       $m_a = 0; 
       $m_a = $months_i;
     } else { $m_a = $months_i; }

   @month = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", 
"Sep", "Oct", "Nov", "Dec"); 
   $month = $month[$m_a];
}
 
sub date {

   if (($m_a == 3) || ($m_a == 5) || ($m_a == 8) || ($m_a == 10)) {
       $days_mon = 30;
   } elsif (($m_a == 1) && ($leap_n == 1)) {
       $days_mon = 29;
   } elsif (($m_a == 1) && ($leap_n == 0)) {
       $days_mon = 28;
   } else { $days_mon = 31; }
   $date_r = $months_l - $months_i;
   $date = (int ($date_r * $days_mon)) + 1;
   if ($date == 0) { $date = 1; }
}

sub weekday {
 
    $wday_r = $days % 7;
    @wday = ("Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"); 
    $wday = $wday[$wday_r];
}

sub hours {

$day_l = abs (($day_r - $day_i) * 24);
$hour_r = $day_l;
 if ($hour_r < 1) {
    $hour_i = 0;
  } else {  
    $hour_i = int ($hour_r);
  }
$hours = $hour_i;
}

sub mins {

$hour_l = abs (($hour_r - $hour_i) * 60);
$min_r = $hour_l;
 if ($min_r < 1) {
    $min_i = 0;
  } else {  
    $min_i = int ($min_r);
  }
$mins = $min_i;
}

sub secs {

$min_l = abs (($min_r - $min_i) * 60);
$sec_r =  $min_l;
$sec_i = int ($sec_r);
$sec_l = $sec_r - $sec_i;
$secs = $sec_i;
  if ($sec_l >= 0.5) { $secs++; } 
}

sub print {
print "Your time was $days days, $hours hours, $mins minutes, and $secs seconds since the beginning of the epoch.\n";

if ($hours < 10) { $hours = "0" . $hours; }
if ($mins < 10) { $mins = "0" . $mins; }
if ($secs < 10) { $secs = "0" . $secs; }

$full_date = ("$wday $month $date $hours:$mins:$secs $year");

print "This corresponds to $full_date.\n";
}
