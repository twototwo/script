#!/usr/bin/perl
#
#  whisker 2.1, copyright 2002 rain forest puppy / rfp(at)wiretrip.net
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#

package whisker;

### BEGIN CONFIG SECTION ###############################################
#
# If you have installed whisker, then indicate the appropriate install dir

$WHISKER_DIR=''; # INITIAL

if($WHISKER_DIR eq ''){
	if($^O =~ /Win32/){
		$WHISKER_DIR='C:\\program files\\whisker\\'; 
	} else {
		$WHISKER_DIR='/usr/local/share/whisker/'; 
	}
}

# Set to 0 if you don't want to see the "Whisker not officially
# installed.." message, only seen if the WHISKER_DIR does not exist

$WHISKER_INSTALL_WARNING = 1;

### END CONFIG SECTION ##################################################

# global variables and schtuff
%G_HOOKS=();		# hook hash
%G_REQ=();		# global requst config hash
%G_RESP=();		# global response hash
%G_O=();		# temporary options values
%G_HOST=();		# per-host data

%G_CONFIG=();		# global configuration data
%{$G_CONFIG{ARRAY}}=();	# global array data values

$G_CONFIG{VERSION}='2.1';

@G_TARGETS=();

#########################################################################

select(STDERR); $|++; select(STDOUT); $|++;

my $LW=0; ### This code checks to see if libwhisker is available
eval 'use LW';
if($@){	$LW=0;
    if(-e $WHISKER_DIR.'LW.pm'){
	eval "require $WHISKER_DIR".'LW.pm';
	if(!$@){$LW++;}}
} else { $LW++; }
if(!$LW){
    print "ERROR:\tLibwhisker not found/installed.\n";
    print "\tDownload libwhisker from www.wiretrip.net/rfp/\n\n";
    exit;
}

my @V=split(/\./,$LW::VERSION);
if($V[0]!=1 && $V[1]<6){
    print "ERROR:\tYou're using an outdated libwhisker version\n";
    print "\tPlease download a newer version from www.wiretrip.net/rfp/\n\n";
    exit;
}

#########################################################################

_init(); # load all the initial config values

# find where we stashed all the plugins and tests
if(-e $WHISKER_DIR && -d $WHISKER_DIR){
	opendir(DATA_DIR,$WHISKER_DIR)||die("Can't open whisker install dir $WHISKER_DIR");
	$G_CONFIG{'WHISKER_DIR'}=$WHISKER_DIR;
} else {
	print STDERR "[ Whisker not officially installed; reading from current directory ]\n"
		if($WHISKER_INSTALL_WARNING);
	opendir(DATA_DIR,'.')||die("Can't open current directory for reading");
	$G_CONFIG{'WHISKER_DIR'}='./';
}

while(my $file=readdir(DATA_DIR)){
	if($file=~m#\.plugin$#){
		if(!wloaddfile($file)){
			print STDERR "There was an error loading $file.  Skipping...\n";
}	}	}


#########################################################################

if(LW::utils_getopts($G_CONFIG{'options'},\%G_O)){
	die("Error parsing options"); }

if((scalar keys %G_O == 0) && wexistdfile('newbie.help')){
	print STDOUT <<EOT;
Whisker has detected you ran whisker without any command line arguments.
If you would like whisker to interactively walk you through configuring
a scan?

(Note: you can remove this message by deleting or renaming the 
       'newbie.help' file.)

EOT
	print STDOUT "Type 'y' for interactive guide, any other key for usage: ";
	my $choice=<STDIN>;
	$choice=~tr/Yy//cd;
	if($choice ne ''){
		wloaddfile('newbie.help')||die("Can't load newbie.help plugin");
	}
}

if(scalar keys %G_O == 0){
	print STDOUT "\n--/ whisker $G_CONFIG{VERSION} / www.wiretrip.net /";
	print STDOUT '-'x38,"\n",$G_CONFIG{'usage'};
	print STDOUT " -T <arg>  Modify the scan via the tweaks specified:\n";
	print STDOUT $G_CONFIG{'tweaks_usage'},"\n\n";
	exit; 
}

foreach (@{$G_HOOKS{'OPTIONS'}}){
	&$_(\%G_O); }

if(!defined $G_O{h} || $G_O{h} eq ''){
	print STDOUT "ERROR: you didn't specify a host to scan.\n";
	exit; }

$G_CONFIG{'target'}=$G_O{h};
$G_CONFIG{'target'}='http://'.$G_CONFIG{'target'} 
	if($G_CONFIG{'target'}!~m#^[a-zA-Z]+://#);

if($G_CONFIG{'target'}=~m#^https://#i && $LW::LW_HAS_SSL==0){
	print STDOUT <<EOT;
Error: you requested an HTTPS site, but SSL support is not available.  You
need to install the Net::SSLeay or Net::SSL Perl module first, which
libwhisker will then automatically use for SSL scanning.
EOT
	exit;
}

if(defined $G_O{I}){ # turn on anti-ids stuff
	$G_REQ{'User-Agent'}='Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; T312461)';
	$G_CONFIG{'ids_modes'}=$G_O{I}; }

if(defined $G_O{t}){
	$G_O{t}=~tr/0-9//cd;
	$G_REQ{whisker}->{timeout}=$G_O{t}||10; }

if(defined $G_O{a}){
	my @p=split(':',$G_O{a},3);
	my $type='basic';
	$type=lc(shift @p) if(scalar @p >2);
	$type=~tr/a-zA-Z0-9//cd;
	if($type ne 'basic' && $type ne 'ntlm'){
		die("Unknown host authorization type: $type"); }
	LW::auth_set_header($type,\%G_REQ,$p[0],$p[1]); 
}

if(defined $G_O{A}){
	my @p=split(':',$G_O{A},3);
	my $type='basic';
	$type=lc(shift @p) if(scalar @p >2);
	$type=~tr/a-zA-Z0-9//cd;
	if($type ne 'basic'){
		die("Unknown proxy authorization type: $type"); }
	LW::auth_set_header('proxy-'.$type,\%G_REQ,$p[0],$p[1]); 
}

$G_CONFIG{'OUT'}=select(STDOUT) if(!defined $G_O{q});

if(defined $G_O{l}){
	open(G_OUT,">$G_O{l}")||die("Can't open $G_O{l} for output");
	select(G_OUT); $|++;
	$G_CONFIG{'LOG'}=select(STDOUT);
}

if(defined $G_O{r}){
	my @tests=split(/:/,$G_O{t});
	foreach (@tests){
	 	$G_CONFIG{'RUN_TESTS'}->{$_}=1; }
	$G_CONFIG{'default_test_exec'}=0;
}

if(defined $G_O{G}){
	$G_CONFIG{'alldirs'}++;
	$G_CONFIG{'allservers'}++;
}

if(defined $G_O{P}){
	my @p=split(/:/,$G_O{P});
	$p[0]=~tr/-a-zA-Z0-9.//cd;
	$p[1]=~tr/0-9.//cd;
	$G_REQ{whisker}->{'proxy_host'}=$p[0];
	$G_REQ{whisker}->{'proxy_port'}=$p[1];
}

if(defined $G_O{T}){ # handle the 'tweaks'
  $G_CONFIG{'save_cookies'}++			if($G_O{T}=~/C/||$G_O{T}=~/A/);
  $G_CONFIG{'track_cookies'}++ 			if($G_O{T}=~/c/);
  push(@{$G_CONFIG{ARRAY}->{'php_exts'}},'.phtml')	if($G_O{T}=~/p/);
  push(@{$G_HOOKS{FINISH}},\&_dump_track)		if($G_O{T}=~/T/);
  $G_CONFIG{'rescan_lowercase'}++ 		if($G_O{T}=~/l/);
  $G_CONFIG{'skip_disclaimer'}++			if($G_O{T}=~/d/);
  $G_CONFIG{'default_test_exec'}=1		if($G_O{T}=~/r/);
  $G_CONFIG{'DEBUG'}=1				if($G_O{T}=~/D/);
  $G_REQ{whisker}->{retry}=0			if($G_O{T}=~/R/);
  $G_REQ{whisker}->{'http_ver'}='1.0'		if($G_O{T}=~/0/);
  $G_CONFIG{'save_moves'}++			if($G_O{T}=~/3/||$G_O{T}=~/A/);
  $G_CONFIG{'report_auth'}++			if($G_O{T}=~/4/||$G_O{T}=~/A/);
  $G_CONFIG{'report_fail'}++			if($G_O{T}=~/5/||$G_O{T}=~/A/);
  $G_CONFIG{'report_ftargets'}++			if($G_O{T}=~/f/||$G_O{T}=~/A/);
  $G_CONFIG{'no_interactive'}++			if($G_O{T}=~/i/);
}

if(defined $G_O{c}){ # crawl options
  $G_CONFIG{'skip_spiderdirs'}++			if($G_O{c}=~/a/);
  $G_CONFIG{'skip_spider'}++			if($G_O{c}=~/d/);
  $G_CONFIG{'migrate_formtargdirs'}++		if($G_O{c}=~/c/);
  $G_CONFIG{'skipaspphp_formtargdirs'}++		if($G_O{c}=~/e/);
  LW::crawl_set_config('use_params',1)		if($G_O{c}=~/p/);
  LW::crawl_set_config('do_head',1)		if($G_O{c}=~/h/);
  LW::crawl_set_config('url_limit',10000)	if($G_O{c}=~/l/);
}
$G_CONFIG{'crawl_depth'}=$G_O{d}||2;


#########################################################################

# so many people don't understand what do to with whisker output...
my $notice=<<EOT; 
Whisker scans for CGIs by checking to see if the server says a particular
URL exists.  However, just because a URL exists does not necessarily mean
it is vulnerable/exploitable--the vulnerability might be limited to only a
certain version of the CGI, and the server might not be using the
vulnerable version.  There is also the case where many scripts use the
same generic CGI name (like count.cgi); in this case, the exact CGI being
used may not be the same one that contains the vulnerability.

Thus, the actual vulnerability of the CGI must be verified in order to get
a true assessment of risk.  Whisker only helps in pointing out the problem
areas.  The next step after scanning with whisker is to review each found
CGI by reviewing the reference URLs or searching for the CGI name on
SecurityFocus.com or Google.com.
EOT
wdisplay(title=>'Notice',text=>$notice) if(!defined $G_CONFIG{'skip_disclaimer'});

# load tests
rewinddir(DATA_DIR);
while(my $file=readdir(DATA_DIR)){
	next if($file!~m#\.test$#);
	if(!wloaddfile($file)){
		print STDERR "Error loading test $file.  Exiting...\n";
		exit;
}	}
closedir(DATA_DIR);

_finish_init();
$G_CONFIG{start_time}=time();

foreach (@{$G_HOOKS{'INIT'}}){ &$_ if(ref($_)); }

# pick our target, which runs G_HOOKS{START} in the process
wtarget($G_CONFIG{target});

_crawler() unless (defined $G_CONFIG{'skip_spider'});
foreach (@{$G_HOOKS{'TESTS'}}){ &$_ if(ref($_)); }
foreach (@{$G_HOOKS{'ANALYSIS'}}){ &$_ if(ref($_)); }
foreach (@{$G_HOOKS{'FINISH'}}){ &$_ if(ref($_)); }

wdisplay(type=>'progress',text=>'Whisker scan completed in '.
	_sec2print(time()-$G_CONFIG{start_time}));
foreach (@{$G_HOOKS{'EXIT'}}){ &$_ if(ref($_)); }

exit; # all done

#########################################################################

sub _sec2print { # print out hours/mins based on seconds
	my ($s,$out,$hours,$mins)=(shift,'',0,0);
	$hours = int($s/3600);
	$mins = int(($s-($hours*3600))/60);
	$out="$hours hours, " if($hours>0);
	$out.="$mins minutes" if($mins>0 || $hours>0);
	$out='less than 1 minute' if($mins==0 && $hours==0);
	return $out;
}

sub _init { # initialize default global config values
	LW::http_init_request(\%G_REQ);
	@{$G_CONFIG{'dir_codes'}}=(200,403);
	@{$G_CONFIG{ARRAY}->{'perl_exts'}}=('','.pl','.cgi');
	@{$G_CONFIG{ARRAY}->{'php_exts'}}=('.php','.php3');
	@{$G_CONFIG{ARRAY}->{cgibin}}=qw(cgi-bin cgi-local htbin cgi cgis 
		cgi-win bin scripts);

	$G_REQ{'User-Agent'}="whisker/$G_CONFIG{VERSION}";
	$G_REQ{whisker}->{'lowercase_incoming_headers'}=1;
	$G_REQ{whisker}->{'ignore_duplicate_headers'}=0;

	%{$G_CONFIG{'COOKIE_JAR'}}=();
	$G_CONFIG{'save_cookies'}=0;
	$G_CONFIG{'DEBUG'}=0;
	$G_CONFIG{'target_count'}=0;
	$G_CONFIG{'track_cookies'}=0;
	$G_CONFIG{'default_test_exec'}=1;
	$G_CONFIG{'rescan_lowercase'}=0;
	$G_CONFIG{'options'}='h:p:S:a:P:A:I:l:T:r:t:d:c:';
	$G_CONFIG{'usage'}=<<EOT;
 -h <arg>  Host to scan (www.host.com or http[s]://www.host.com:80/)
 -a <arg>  HTTP authorization (in the form of [type:]user:pass)	
 -P <arg>  Use HTTP proxy (in the form of proxy_host:port)
 -A <arg>  Proxy HTTP authorization (in the form of [type:]user:pass)	
 -t <arg>  Specify the timeout, in seconds (default: 10)
 -I <arg>  Enable the given IDS-evasive modes (see docs for mode codes)
 -S <arg>  Override the Server banner
 -G        Generic/dumb mode; force all scans in all dirs on all servers
 -r <arg>  Run only the given tests (in the form of id:id:id:...)
 -l <arg>  Log output to specified file
 -q        Do not print results to STDOUT
 -d <arg>  Depth to crawl (default: 2; main homepage counts as 1)
 -c <arg>  Crawl options:
           d  Do not crawl site
           p  Take URL parameters into account when crawling
           h  Use HEAD requests for potential speed increase
           l  Raise the URL buffer limit from 1,000 to 10,000
           a  Do not populate SPIDER directory array
           c  Add form target directories to CGIBIN directory array
           e  Do not add .asp or .php form targets to CGIBIN dir array
EOT
	$G_CONFIG{'tweaks_usage'}=<<EOT;
           c  Track and handle cookies like a normal client would
           p  Include phtml in generic PHP extensions
           l  Double scan all mixed-case URLs as lowercase
           d  Suppress CGI disclaimer in output report
           i  Suppress all interactive questions
           r  Invert the -r parameter (as in, do *not* run those tests)
           R  Turn off libwhisker 'retries' feature
           0  Use HTTP/1.0 (that is a zero, and not the letter 'o')
           3  Report all move (3xx) responses
           4  Report all authentication (401) responses
           5  Report all failure (500) responses
           f  Report all form targets
           C  Report all cookies given during scanning
           A  Report everything
           D  Print debug output to STDERR
           T  Dump TRACK hash to track.log in current dir when done
EOT

}

sub _dump_track { # dump host track results to the track.log
	my ($b,$n,$a)=('track.log','track.log',0);
	while(-e $n){
		$n=$b.$a; $a++; }
	LW::dumper_writefile($n,'track',$G_HOST{TRACK});
}

sub _finish_init {
	my $code='sub _code_dir { my $code = shift;';
	foreach (@{$G_CONFIG{'dir_codes'}}){
		$code.="return 1 if(\$code==$_);";} 
	$code.='return 0; }';
	eval $code;

	push(@{$G_HOOKS{'ANALYSIS'}},\&_record_reporter);

}

sub wgeneral {
	my ($d,$f,%o)=@_;
	return if(!defined $o{id});
	if(wtest($o{id})){
		wlog(%o) if(wexist($d,$f));
	}
}

sub wtarget {
	my $target=shift;

	# call FINISH hooks for prior target
	if($G_CONFIG{'target_count'}>0){
		foreach (@{$G_HOOKS{'FINISH'}}){ &$_; }
	}

	LW::utils_split_uri($target,\%G_REQ);
	LW::http_fixup_request(\%G_REQ);
	%G_HOST=();		# reset the HOST datas:
	%{$G_HOST{RECORD}}=();	# recorded data
	%{$G_HOST{ARRAY}}=();	# directory array data
	@{$G_HOST{FOUND}}=();	# current found URLs
	%{$G_HOST{IDS}}=();	# IDs of executed tests
	%{$G_HOST{TRACK}}=();	# URL tracking data
	%{$G_HOST{SERVER}}=();	# server banners
	my ($k,$v); # transfer global arrays to host array
	while(($k,$v)=each %{$G_CONFIG{ARRAY}}){
		@{$G_HOST{ARRAY}->{$k}}=@$v; }

	# call START hooks for this target
	foreach (@{$G_HOOKS{'START'}}){ &$_; }

	wdisplay(type=>'progress',text=>"Beginning scan against $G_CONFIG{target}");

	$G_CONFIG{'target_count'}++;
}

sub warray {
	my ($name,@vals)=@_;
	return @{$G_HOST{ARRAY}->{$name}} if(wantarray);
	if(defined $vals[0]){
		push(@{$G_HOST{ARRAY}->{$name}},@vals);
	} else { delete $G_HOST{ARRAY}->{$name}; }
}

sub wtest {
	my $test=shift;
	my $run=$G_CONFIG{'default_test_exec'};
	$run=(($run+($G_CONFIG{'RUN_TESTS'}->{$test}))%2) 
		if( defined $G_CONFIG{'RUN_TESTS'}->{$test});
	return $run;
}

sub wlog {
	goto &{$G_HOOKS{wlog}} if(defined $G_HOOKS{wlog});
	my %opts = @_;

	$opts{urls}=join("\n",@{$G_HOST{FOUND}}) if(!defined $opts{urls} && 
		scalar @{$G_HOST{FOUND}} >0);
	$opts{id}||='-';
	$G_HOST{IDS}->{$opts{id}}++;

	if(!defined $opts{title}){
		my $url=$G_HOST{FOUND}->[0];
		if(defined $url){
			$opts{title}=$1 if($url=~m#/([^/]+)$#);
		}
	}

	$opts{reference}.="http://online.securityfocus.com/bid/$opts{bid}\n"
		if(defined $opts{bid});
	$opts{reference}.="http://cve.mitre.org/cgi-bin/cvename.cgi?name=$opts{cve}\n"
		if(defined $opts{cve});
	if(defined $opts{neo}){
		$opts{reference}.="http://archives.neohapsis.com/archives/$opts{neo}\n";
		delete $opts{neo};
	}

	if(!defined $opts{text}){
		if(defined $opts{references}){
	$opts{text}="See references for specific information on this vulnerability.";
		} else {
	$opts{text}="No specific information is provided for this item.";
		}
	}

	if(defined $G_HOST{'auto_notice'}){
		$opts{notice}=$G_HOST{'auto_notice'}; 
		delete $G_HOST{'auto_notice'};
	}

	wdisplay(%opts);
}

sub wdisplay {
	goto &{$G_HOOKS{wdisplay}} if(defined $G_HOOKS{wdisplay});
	my %opts = @_;

	if(defined $opts{type} && $opts{type} eq 'raw'){
		syswrite($G_CONFIG{OUT},$opts{text},length($opts{text})) 
			if(defined $G_CONFIG{OUT});
		syswrite($G_CONFIG{LOG},$opts{text},length($opts{text})) 
			if(defined $G_CONFIG{LOG});
		return;
	}

	delete $opts{type};
	my $out = '-'x76;
	$out.="\n";

	my @special=qw(title id bid cve severity);
	foreach (@special) { 
		if(defined $opts{$_}){
			$out.=ucfirst($_).': '.$opts{$_}."\n";
			delete $opts{$_};}}
	if(defined $opts{urls}){
		if($opts{urls}=~s/\n/\n\t/g){
			$out.="Found URLs:\n\t$opts{urls}\n";
		} else {
			$out.="Found URL: $opts{urls}\n";
		}
		delete $opts{urls};
	}

	while( ($k,$v)=each %opts){
		next if($k eq 'text' || $k eq 'reference');
		$out.=ucfirst($k).": $v\n"; }

	$out.="\n";
	$out.=$opts{text}."\n" if(defined $opts{text});
	$out.="\nReferences:\n".$opts{reference}."\n"
		if(defined $opts{reference});
	$out.="\n";
	syswrite($G_CONFIG{OUT},$out,length($out)) if(defined $G_CONFIG{OUT});
	syswrite($G_CONFIG{LOG},$out,length($out)) if(defined $G_CONFIG{LOG});
}


sub wexist {
	goto &{$G_HOOKS{wexist}} if(defined $G_HOOKS{wexist});
	my ($dirstr,$filestr)=@_;

	delete $G_HOST{'auto_notice'};
	my (@found,@dirs);
	$dirstr=~tr/ \t//d;
	if(index($dirstr,',') >=0) {
		@dirs=split(',',$dirstr);
	} else {
		push(@dirs, $dirstr); }
	foreach (@dirs) {	
	    if($_ ne '/'){
		s;^/;;;s;/$;;; # I love perl code like this ;)
		my @dp=split('/',$_);
		LW::utils_recperm('/',0, \@dp, \@found, 
			\&wdiscoverdir, $G_HOST{TRACK}, $G_HOST{ARRAY},
			\&_code_dir);
	    } else { push(@found,'/'); 
	}   } 
	return 0 if((scalar @found)==0); # no valid dirs

	my %req;
	_ch(\%G_REQ,\%req);
	my $F=0;
	@{$G_HOST{FOUND}}=();	
	my @EXTS=('');
	if($filestr=~s#\[(.+)\]$##){
		my $t=$1; $t=~tr/ //d;
		if(substr($t,0,1) eq '@'){
			$t=~tr/@//d;
			@EXTS=@{$G_HOST{ARRAY}->{lc($t).'_exts'}};
		} else {
			@EXTS=split(/,/,$t);
	}	}

	my %RESP;
	my $D; do{ $D=1;
	map {	my $d=$_; foreach my $e (@EXTS) { $e=~tr/ //d;
		my $x="$d$filestr$e";
		$x=~s#/{2,}#/#g;
		$req{whisker}->{uri}=$x;
		if(!_do_request(\%req,\%RESP)){
			_d_response(\%RESP);
			$G_HOST{TRACK}->{"$d$filestr$e"}=$RESP{whisker}->{code};
			if(_code_page($RESP{whisker}->{code})){
				$F++;
				push(@{$G_HOST{FOUND}},$x); }}
	  }} @found;
	  if($filestr=~tr/A-Z// && $G_CONFIG{'rescan_lowercase'}){
		$D=0; $filestr=lc($filestr); }
	} while($D==0);

	return $F;
}


sub wdiscoverdir {
	return 1 if(defined $G_CONFIG{alldirs});
	my ($dir,%resp)=(shift);
	$dir=~s#/+#/#g;
	$dir.='/' if(substr($dir,-1,1) ne '/');
	return _code_dir($G_HOST{TRACK}->{$dir}) if(defined $G_HOST{TRACK}->{$dir}&&
		$G_HOST{TRACK}->{$dir} ne '?');
	my %req;
	_ch(\%G_REQ,\%req);
	$req{whisker}->{uri}=$dir;
	return 0 if _do_request(\%req,\%resp);
	_d_response(\%resp);
	$G_HOST{TRACK}->{$dir}=$resp{whisker}->{code};
	return _code_dir($resp{whisker}->{code});
}


sub wserver {
	my ($k,$v,$param,$addflag)=('','',@_);

	$d1=0; $d1++ if(defined $param);
	$d2=0; $d2++ if(defined $addflag);


	if(!defined $param){ # check to see if we have a banner
		return 1 if(scalar keys %{$G_HOST{SERVER}});
		return 0;
	}

	$param=lc($param);
	if(defined $addflag && $addflag >0){ # set the value
		$G_HOST{SERVER}->{ $param }++;
		return 1;
	}

	return 1 if(defined $G_CONFIG{allservers});

	foreach (keys %{$G_HOST{SERVER}}){
		my $ndx=index($_,$param); 
		return 1 if($ndx != -1);
	}
	return 0;
}

sub warrayhas {
	my ($val,$name)=@_;
	foreach (@{$G_HOST{ARRAY}->{$name}}){
		return 1 if($val eq $_); }
	return 0;
}

sub _code_page {
	goto &{$G_HOOKS{code_page}} if(defined $G_HOOKS{code_page});
	my $code = shift;
	return 1 if($code==200);
	return 0;
}

sub _uniq_array {
	my ($name,%x)=(shift);
	return if(!defined $G_HOST{ARRAY}->{$name});
	foreach (@{$G_HOST{ARRAY}->{$name}}){ $x{$_}++; }
	@{$G_HOST{ARRAY}->{$name}} = keys %x;
}

sub _d_response {
	my $hr=$_[0];
	my $wr=$$hr{whisker};

	if(!defined $$wr{lowercase_incoming_headers} ||
			$$wr{lowercase_incoming_headers}==0){
		LW::utils_lowercase_headers($hr);
	}

	if(defined $$hr{'set-cookie'}){
		if($G_CONFIG{'save_cookies'} || defined $G_HOOKS{d_cookie}){
			my @cookies;
			if(ref($$hr{'set-cookie'})){
				push @cookies, @{$$hr{'set-cookie'}};
			} else { push @cookies, $$hr{'set-cookie'}; }
			if(defined $G_HOOKS{d_cookie}){
				foreach $cookie (@cookies){
					&{$G_HOOKS{'d_cookie'}}($cookie,
						$$hr{whisker}->{uri}); }}
			push(@{$G_HOST{RECORD}->{COOKIES}},@cookies) 
				if($G_CONFIG{'save_cookies'});
		}
	}

	my $C=$$wr{http_resp};
	# handle custom-404's
	if(defined $G_CONFIG{'404_alternate'}){
		if($G_CONFIG{'404_alternate'}==200){
			if($C==200 && LW::md5($$wr{data}) eq
					$G_CONFIG{'200_as_404_data'}){
				$C=$$wr{code}=$$wr{http_resp}=404;
				print STDERR "404 $$wr{uri} (custom 404 remap)\n"
					if($G_CONFIG{'DEBUG'}>0);
			}
		} else { # 302
			if($C==302 && $$hr{location} eq $G_CONFIG{'302_as_404_data'}){
				$C=$$wr{code}=$$wr{http_resp}=404;
				print STDERR "404 $$wr{uri} (custom 404 remap)\n"
					if($G_CONFIG{'DEBUG'}>0);
	}	}	}

	# record interesting info
	if($C==302 || $C==301 || $C==307 || $C==303){
		push(@{$G_HOST{RECORD}->{MOVES}},"$$wr{uri} -> $$hr{location}"); }
	if($C==401){
		push(@{$G_HOST{RECORD}->{AUTH}},"$$wr{uri}"); }
	if($C==500){
		push(@{$G_HOST{RECORD}->{FAIL}},"$$wr{uri}"); }

	if(defined $$hr{'content-length'} && $$hr{'content-length'}==0 && $C==200){
		$G_HOST{'auto_notice'}='content length is 0; this could be a false/fake CGI';
	}

	if(defined $$hr{server}){
		if(!wserver()){
			wserver($$hr{server},1);
	                my $text=<<EOT;
The server returned the following banner:
        $$hr{server}
EOT
	                wlog(id=>100,text=>$text,severity=>'Informational',
				title=>'Server banner');
		} elsif(!wserver($$hr{server})){
			wserver($$hr{server},1);
	                my $text=<<EOT;
Notice!  The server banner changed during scanning to the following:
        $$hr{server}
EOT
	                wlog(id=>107,title=>'Server banner changed',text=>$text,
				severity=>'Informational');
	}	}

	goto &{$G_HOOKS{d_response}} if(defined $G_HOOKS{d_response});
}

sub _record_reporter {
	my %unique;

	my @W=(	'COOKIES:save_cookies:The following cookies were encountered while scanning:Encountered cookies',
		'MOVES:save_moves:The following redirections were encountered while scanning:Encountered moves/redirections',
		'AUTH:report_auth:The following URLs requested authentication:Authentication requests',
		'FAIL:report_fail:The following URLs caused server failures:Encountered failures',
		'FORMTARGETS:report_ftargets:The following URLs were the targets of forms:Encountered form targets'
	);

	foreach (@W){
		my @p=split(/:/,$_);
		if(scalar @{$G_HOST{RECORD}->{$p[0]}}>0 && defined $G_CONFIG{$p[1]}){
			%unique=();
			foreach (@{$G_HOST{RECORD}->{$p[0]}}){ $unique{$_}++; }
			my $text="$p[2]:\n\t";
			$text.=join("\n\t",keys %unique)."\n";
			wdisplay(text=>$text,title=>$p[3],severity=>'Informational');
		}
	}

}

sub _crawler {

	wdisplay(type=>'progress',text=>'Whisker is currently crawling the website; please be patient.');

	LW::crawl_set_config('source_callback'=>\&_crawl_scallback,
		'save_skipped'=>1,
		'reuse_cookies'=>0);

	LW::crawl_set_config('save_cookies'=>1) if(defined $G_CONFIG{'save_cookies'});
	LW::crawl_set_config('reuse_cookies'=>1) if(defined $G_CONFIG{'track_cookies'});

	my $start=$G_CONFIG{'target'};
	$start='http://'.$start if($start!~m#^[a-zA-Z]+://#);
	$start=~m#^([a-zA-Z]+://[^/]+)#;
	$start="$1/";

	LW::crawl($start,$G_CONFIG{'crawl_depth'},$G_HOST{TRACK},\%G_REQ);
	wdisplay(type=>'progress',text=>'Whisker is done crawling the website.');

	my ($k,$v,%x);
	while( ($k,$v)=each %LW::crawl_forms){
		push(@{$G_HOST{RECORD}->{FORMTARGETS}},$k); 
		if(defined $G_CONFIG{'migrate_formtargdirs'}){
			$k="$G_CONFIG{'target'}/$k" if($k!~m#^[a-z]+://#i);
			my @p=LW::utils_split_uri($k);
			next if(defined $p[2] && $G_CONFIG{target}!~/$p[2]/);
			next if($p[0]=~m#\.(asp|php|phtml)[x34]*$# && defined $G_CONFIG{'skipaspphp_formtargdirs'});
			$p[0]=~s#/[^/]*$#/#; 
			$x{$p[0]}++ if($p[0] ne '/' && $p[0] ne '');
		}
	}

	if(defined $G_CONFIG{'migrate_formtargdirs'}){
		push(@{$G_HOST{ARRAY}->{cgibin}},keys %x);
		_uniq_array('cgibin');
	}

	my %temp=();
	@{$G_HOST{ARRAY}->{'spider'}}=();
	while( ($k,$v)=each %{$G_HOST{TRACK}}){
		$k=~s#/[^/]*$##; $k=~s#^/##;
		next if($k eq '');
		my @p=split(/\//,$k);
		my $o='/';
		foreach (@p){
			$o.="$_/";
			$G_HOST{TRACK}->{$o}=200 if(!defined $G_HOST{TRACK}->{$o});
			$temp{$o}++ unless(defined $G_CONFIG{'skip_spiderdirs'});
		}
	}

	push(@{$G_HOST{ARRAY}->{'spider'}}, keys %temp) 
		unless(defined $G_CONFIG{'skip_spiderdirs'});

	my $nbc=0;
	while( ($k,$v)=each %LW::crawl_server_tags){
		next if($k eq '');
		if(!wserver($k)){
			wserver($k,1);
			$nbc++;
		}
	}

	if(scalar $nbc >1){
		my $text="The server returned multiple banners during the course of crawling:\n\t";
		$text.= join("\n\t",keys %{$G_HOST{SERVER}});
		$text.="\n";
		$text.="This could be the result of a load balancing or reverse proxy setup.\n";
		wlog(id=>103,text=>$text,severity=>'Informational', title=>'Server banner change');
	}

	if(defined $G_CONFIG{'track_cookies'} && %LW::crawl_cookies){
		push(@{$G_HOST{RECORD}->{'COOKIES'}}, keys %LW::crawl_cookies);
	}

}

sub _crawl_scallback {
	_d_response($_[1]);
	goto &{$G_HOOKS{d_crawl_scallback}} 
		if(defined $G_HOOKS{d_crawl_scallback});
}

sub _shutdown {
	wdisplay(text=>"Error: there was a problem connecting to the server.  The specific error returned is:\n$G_RESP{whisker}->{error}\n");
	foreach (@{$G_HOOKS{'EXIT'}}){ &$_; }
	exit;
}

sub _do_request { # wrapper for a few things
	my ($req,$resp)=@_;
	my %R;
	LW::cookie_write(\%{$G_CONFIG{'COOKIE_JAR'}},$req)
		if(defined $G_CONFIG{'track_cookies'});
	if(defined $G_CONFIG{'ids_modes'}){
		_ch($req,\%R); $req=\%R;
		LW::anti_ids($req,$G_CONFIG{'ids_modes'});
	}
	my $ret=LW::http_do_request($req,$resp);
	LW::cookie_read(\%{$G_CONFIG{'COOKIE_JAR'}},$req)
		if(defined $G_CONFIG{'track_cookies'});
	print STDERR "$$resp{whisker}->{code} $$req{whisker}->{uri}\n"
		if($G_CONFIG{'DEBUG'}>0);
	return $ret;
}


sub _ph {
	my ($r,$o)=shift;
	print STDOUT <<EOT;
Do you need a HTTP proxy in order to reach '$$r{whisker}->{host}'?
EOT
	do {
		print "Choice [y or n]: ";
		my $x=<STDIN>;
		$x=~tr/ynYN//cd;
	} while ($x eq '');

	if($x=~/y/i){
		my $loop=1;
		do {
			print STDOUT "Enter proxy host address: ";
			my $host=<STDIN>; $host=~tr/ \t\r\n//d;
			print STDOUT "Proxy port: ";
			my $port=<STDIN>; $port=~tr/0-9//cd;
			print STDOUT "Proxy username (or leave blank if not needed): ";
			my $user=<STDIN>; $user=~tr/ \t\r\n//d;
			my $pass='';
			if($user ne ''){
			print STDOUT "Proxy password for given username: ";
				$pass=<STDIN>; $pass=~tr/\r\n//d;
			}
			print STDOUT <<EOT;
Does the following information look correct?
Proxy host:	$host
Proxy port:	$port
Proxy username:	$user
Proxy password:	$pass

Enter 'y' to continue, 'n' to go back and change something.
EOT
			do {
				print "Choice [y or n]: ";
				my $x=<STDIN>;
				$x=~tr/ynYN//cd;
			} while ($x eq '');
			$loop=0 if($x=~/y/);
		} while($loop);

		$$r{whisker}->{proxy_host}=$host;
		$$r{whisker}->{proxy_port}=$port;
		if($user ne ''){
			LW::auth_set_header('proxy-basic',$r,$user,$pass);
		}
	}
	LW::http_fixup_request($r);
	return LW::http_do_request($r,$o);
}


sub _ch { # copy whisker hash; overcomes reference problems
	my ($from,$to)=@_;
	%$to=%$from;
	my %temp=%{$$from{whisker}};
	$$to{whisker}=\%temp;
}

sub wloaddfile {	# load data file out of whisker data dir
	my ($file)=shift;
	return 0 if(!-e $G_CONFIG{WHISKER_DIR}.$file);
	eval { require "$G_CONFIG{WHISKER_DIR}$file" };
	if($@){ return 0; }
	return 1;
}

sub wopendfile { # open data file out of whisker data dir
	my ($rmode,$file,$mode)=('',shift,lc(shift));
	$mode||='r';
	$mode=~tr/rw//cd;
	return undef if($mode eq '');
	return undef if(!-e $G_CONFIG{WHISKER_DIR}.$file);
	$rmode=0 if($mode eq 'r');
	$rmode=1 if($mode eq 'w');
	$rmode=2 if($mode eq 'rw');
	return undef if(!sysopen(IN,"$G_CONFIG{WHISKER_DIR}$file",$rmode));
	return IN;
}

sub wexistdfile {
	my ($file)=shift;
	return 0 if(!-e $G_CONFIG{WHISKER_DIR}.$file);
	return 0 if(!-f $G_CONFIG{WHISKER_DIR}.$file);
	return 1;
}
