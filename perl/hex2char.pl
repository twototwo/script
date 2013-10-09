#!/usr/bin/perl
#@upker.net
#HEX->Char

print "Usage:$0 HEX\n";
$data= shift;
my @hex = $data  =~ m/0x(..),/g;
print chr ( oct ("0x". $_ ) ) foreach @hex;
print "\n";
