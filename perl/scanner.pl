#!/usr/bin/perl 
use strict;
use warnings;
use IO::Handle;
use Socket;
use threads;

print "[+]SimpleScanner!\n";
print "[+]\@upker.net\n";
print "[+]H4ck 7he pl4n3t!\n";
print "-------------------------------------\n";
####################
my $port = 80;
my $ip = '192.168.1.';
#####################
my @t;
for( my $i = 1; $i < 255; $i++ )
{
	my $host = $ip.$i;
	my $thread_hd = threads->create('try_connect', $host, $port);
	push(@t,\$thread_hd);
}
foreach my $thread (@t) {
	if( defined($thread)){
		$$thread->join();
	}
}
print "-------------------------------------\n";
sub try_connect{
	my ($host, $port) = @_;
	socket(CLIENT, AF_INET, SOCK_STREAM, getprotobyname('tcp')) || die "create socket failed: $!";
	my $packhost = inet_aton($host);
	my $address = sockaddr_in($port, $packhost);
	if( connect(CLIENT, $address) ){
	print "[+]Connect http://$host:$port OK!\n";  
	}
close(CLIENT);
}
