#!/usr/bin/perl -w
use strict;
use Socket;
use threads;
use LWP::UserAgent;
print "[+]Same C-ip Site.\n";
	print "[+]\@upker.net\n";
if (@ARGV!=2) {
        print "[+]Usage:$0 127.0.0.1 save_file.txt\n";
        print "\t $0 www.xxooxox.com save_file.txt\n";
        exit;
}
my ($ip,$save_file) = @ARGV;
if (!($ip =~ /\d+\.\d+.\d+.\d+$/)) {
        $ip =~ s/^http:\/\///ig;
        $ip = inet_ntoa(inet_aton($ip));
        print "[+]$ARGV[0]-->$ip\n";
}

open (FILEI,">$save_file");
my $i=1;
my $thread;
while ($i < 255) {
        my $maxthread = 20;
    	while(scalar(threads->list()) < $maxthread){
                  #$ip =~ s/(\d+)$/$i/;
                  $thread = threads->create(\&get_domain,$ip);
                  $i++;
    	}
        foreach $thread(threads->list(threads::joinable)){                 
                            $thread->join();
   	}
}

while (scalar(threads->list())) {
      	foreach $thread(threads->list(threads::joinable)){                 
                            $thread->join();
                }
        sleep (2);
}

sub get_domain {
                   my $ip = shift;
                   my @result;
                   my $ua = LWP::UserAgent->new;
                   $ua->timeout(10);
                   $ua->env_proxy;
                   my $url = "http://www.reverseip.us/?url=$ip";
                   my $response = $ua->get("$url");
                   my $tmp = $response->content;
		   @result = ($tmp =~/"\>([0-9a-z.]+)\<\/a\>/g);
		   foreach my $result (@result)
		   {
		   print FILEI "$ip:\n";
		   print FILEI "$result\n";
		   print "[=]$result\n";
		   }
                   print "[+]$ip:\n"            
}

