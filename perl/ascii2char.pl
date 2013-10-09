#!/usr/bin/perl
#@upker.net
#ASCII->Char

print "Usage:$0 ASCII\n";
#print "eg:$0 117,112,107,101,114,46,110,101,116\n";
$ascii= shift;
$ascii=~ s/\s/,/g;
@ascii=split(/[^0-9A-Za-z]/,$ascii);
print "Char:\n";
foreach $asc(@ascii){
$char=chr($asc);
print "$char";
}
print "\n";
