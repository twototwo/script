#!/usr/bin/perl

# convoluted whisker 2.x install script

$|++;

if($^O =~ /Win32/){
	$WHISKER_DIR='C:\\program files\\whisker\\'; 
	$SEP='\\';
} else {
	$WHISKER_DIR='/usr/local/share/whisker/';
	$LINK_DIR='/usr/local/bin/';
	$SEP='/';
}

$WHISKER_DIR=getdir($WHISKER_DIR,'Whisker data files will be placed in');

if($^O !~ /Win32/){
	$LINK_DIR=getdir($LINK_DIR,'A whisker symlink will be made in');
	$LINK_DIR.=$SEP if($LINK_DIR!~m/$SEP$/);
}


&install;

exit;


sub install {
	$WHISKER_DIR.=$SEP if(substr($WHISKER_DIR,-1,1) ne $SEP);
	my $file;

	opendir(DIR,'.')||die("Can't open current directory for reading!");

	copywhisker($WHISKER_DIR.'whisker.pl',$WHISKER_DIR);
	chmod(0755,$WHISKER_DIR.'whisker.pl');

	while($file=readdir(DIR)){
		next if($file=~/^\./);
		next if(-d $file);
		next if($file eq 'install.pl');
		next if($file eq 'whisker.pl');
		copyfile($file,"$WHISKER_DIR$file");
	}

	closedir(DIR);

	if($^O =~ /Win32/){
		make_win_bat($WHISKER_DIR);
	} else {
		print STDOUT "Making whisker symlink...";
		symlink($WHISKER_DIR.'whisker.pl',$LINK_DIR.'whisker')
			|| die("Can't make symlink");
		print "done.\n";
	}

	print "\n\nAll done installing!\n\nTo run whisker, type:\n\n\t";

	if($^O=~/Win32/){
		print "whisker\n\n";
	} else {
		print $LINK_DIR,"whisker\n\n";
	}

}


sub yesno {
	my $x='';
	do {
		print "Choice [y/n]: ";
		$x=<STDIN>;
		$x=~tr/YyNn//cd;
	} while ($x eq '');
	return $x;
}

sub copywhisker { # whisker.pl is special...
	my ($to,$dir)=@_;

	print STDOUT "Installing whisker.pl...";
	open(IN,'<whisker.pl')||die("Can't open whisker.pl for reading");
	open(OUT,">$to")||die("Can't open $to for writing");

	binmode(IN);
	binmode(OUT);

	my $replaced=0;
	while(<IN>){
		if(m/\$WHISKER_DIR=''; # INITIAL/ && !$replaced){
			$dir=~s/\\/\\\\/g;
			$_ = "\t\$WHISKER_DIR='$dir'; # INSTALLED\n";
			$replaced++;
		}
		print OUT $_;
	}

	close(IN);
	close(OUT);
	print STDOUT "done.\n";
}


sub copyfile { # I hate having to do this
	my ($from,$to)=@_;
	print STDOUT "Copying $from...";
	open(IN,"<$from")||die("Can't open $from for reading");
	open(OUT,">$to")||die("Can't open $to for writing");

	binmode(IN);
	binmode(OUT);

	my ($read,$wrote,$data);
	while(<IN>){
		print OUT $_ || die("Error writing to $to");
	}

	close(IN);
	close(OUT);
	print STDOUT "done.\n";
}

sub make_win_bat {
	my ($tdir,$dir)=('',shift);

	print STDOUT "Creating whisker.bat file...";
	
	if(defined $ENV{systemroot}){
		$tdir=$ENV{systemroot};
	} elsif(defined $ENV{windir}){
		$tdir=$ENV{windir};
	} elsif(-e 'c:\\winnt' && -e 'c:\\winnt'){
		$tdir='c:\\winnt';
	} elsif(-e 'c:\\windows' && -e 'c:\\windows'){
		$tdir='c:\\windows';
	} else {
		die("\nUnable to figure out where to put whisker.bat file");
	}

	my $target="$tdir\\whisker.bat";

	open(OUT,">$target")||die("Can't open $target for writing");

print OUT <<EOT;

\@echo off
perl "$dir\\whisker.pl" \%*
pause

EOT

	close(OUT);
	print STDOUT "done.\n";
}



sub getdir {
	my ($DIR,$phrase)=@_;

print STDOUT <<EOT;
$phrase the following directory:

	$DIR

If this is OK, then type 'Y', otherwise type 'N'.

EOT

my $ans=&yesno;

if($ans=~m/n/i){

  do {
	print STDOUT <<EOT;

You have opted to install into a different directory.  Please type a new
absolute directory path.

EOT
	print STDOUT "Directory: ";
	$DIR=<STDIN>;
	$DIR=~tr/\r\n//d;

print STDOUT <<EOT;

$phrase the following directory:

	$DIR

If this is OK, then type 'Y', otherwise type 'N'.

EOT
	$ans=&yesno;

	if($ans=~/y/ && !(-e $DIR && -d $DIR)){
		mkdir($DIR,0755)||die("Failed to create $DIR");
	}

  } while($ans!~m/y/i);
} else {
	if(!(-e $DIR && -d $DIR)){
		mkdir($DIR,0755)||die("Failed to create $DIR");
	}
}

	return $DIR;
}
