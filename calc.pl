#!/usr/bin/perl

# A very simple one-line calculator
# takes sum as it's argument, probably best to use quotes to
# stop bash getting confused

# calc "(2 + 3) * 4"

# Copyleft (GNU GPL) Jonathan Riddell (jr@jriddell.org) 2000

print eval(join('', @ARGV)) . "\n";

