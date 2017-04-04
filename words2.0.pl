#usr/bin/perl

# This program takes in a cleaned up file from extract.pl.
# It first goes through and saves all the words into the hash %words. 
# The hash is then printed out as a dirful of files, each one of which lists how many times each word given month. 

# Written by Joey Stanley. Altered by Barry Shelton.
# August 7, 2015/Feb. 2017

########################
#####Getting Set Up#####
########################
use strict;
use warnings;
no warnings "experimental::autoderef";
use feature 'say';
use open qw/ :std :encoding(utf8) /;
use feature 'say';
use diagnostics;
require Parallel::ForkManager; 
require Benchmark::Timer; 
require Cpanel::JSON::XS; 
Benchmark::Timer->import;
Parallel::ForkManager->import;
Cpanel::JSON::XS->import;
use Cpanel::JSON::XS qw(encode_json decode_json);
my $start = time;
my $dir = "./";
my $outdir =  "$dir/OutHash"; 
mkdir ($outdir) unless(-d $outdir);  
die $! unless -e $outdir;
my $Nforks = 6;															# If you run more forks than your memory can handle, you might crash your machine. Or it could just run abysmally slow.
my $fm = Parallel::ForkManager->new($Nforks);                           # Six forks will use over 20 gigs of memory toward the end of the run. If you have a fast processor and low memory, make a swap file on a HDD or USB drive. 
my @fps = (glob("$dir/JSON/*"));  										# The program can also be stopped at any time and any files you have will be complete.
																		
my %words;
my $wordCount = 0;
my $focus = "month";													
my $date;
my $body;
say "Input Info\t\t\t\t\tOutput Info";													

###################
#####Main Loop#####
###################
for (my $i = 0; $i < @fps; $i++) {  									#Set iterator for forks	
	$fm->start and next;												#Start forking
	my $fp = ($fps[$i]);	
	open my $fh, "<", $fp or die "can't read open '$fp': $_";
	say "Reading in file $fp";
	while (<$fh>) { 
	&ParseJSON ($_);
	my $date = $date;
	my $body = $body;
	    next unless $body;
	    next if $body =~ /\A\s*\Z/; 									# If there's nothing left, junk it.
		next if $body =~ /\[deleted\]/;									#Call to sub on JSON strings												
	my ($month, $day, $year) = split(/\//, $date);						# First get the datatime info.
	my $timePeriod = "";												# Depending on the time frame you're interested in, it'll create a "timerPeriod" string.
	if ($focus eq "day") {
		$timePeriod = $year.'/'.$month.'/'.$day;
	} elsif ($focus eq "month") {
		$timePeriod = $month."-".$year;									# Take the body, and send it down to &trackWords(), with the date.
	}																	# This regex here defines what a word actually is (anything beginning with a letter and having 0 or more letters, apostrophes, or hyphens)
	$body =~ s/([A-Za-z]+([A-za-z'-]*))/ trackWords($1, $timePeriod)/gei;																
	}
	
	close $fh or die "can't close '$fp': $_";
	say "\t\t\t\t\t\tDone Reading $fp.";
	say "\t\t\t\t\t\tFound ".(addCommas($wordCount))." words.";
	$fp =~ m/\.\/\/JSON\/(.+)/;
	my $fn = $1;
	
	say "\t\t\t\t\t\tWriting out data to filepath: /OutHash/$fn.hash.txt ";

	open WORDS, ">$outdir/$fn.hash.txt";
	for my $w (sort keys %words) { 										# print them alphabetically
	my $n = 0;	
	for my $date (sort keys $words{$w}) {								# Go through each date and count how many times the words was there.
		$n += $words{$w}{$date};
	}
	say WORDS "$w\t$n";	
}
close WORDS;
		
		my $duration = time - $start;
		if ($duration > 3600){
		$duration = $duration / 3600;        		 					#Benchmarking and Runtime
		say "\t\t\t\t\t\tI've been running for $duration hours now";
			}elsif($duration > 60){	
				$duration = $duration / 60;        
				say "\t\t\t\t\t\tI've been running for $duration minutes now";
			}else{
				say "\t\t\t\t\t\tI've been running for $duration seconds now";
			}
			say "";
								
	$fm->finish;
}
$fm-> wait_all_children;
say "Done!";


my $duration = time - $start;
		if ($duration > 3600){
		$duration = $duration / 3600;        		 					#Benchmarking and Runtime
		say "Total Runtime: $duration hours";
			}elsif($duration > 60){	
				$duration = $duration / 60;        
				say "\tTotal runtime: $duration minutes";
			}else{
				say "\tTotal runtime: $duration seconds";
			}															#Hashtag"TheEnd"
	
#####################
#####SubRoutines#####
#####################


sub ParseJSON {
      	my $json = shift;
      	my $decoded = decode_json $json;
      	$body = $decoded->{'body'};
      	$date = $decoded->{'created_utc'};
      	$date = &DT ($date);
      	$body = &specialCharacters($body);
      	return ($body, $date);
}


sub DT{my $date = shift;
			# Convert DT stamp into a readable format
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($date);
			$mon++; 

			$sec  = "0$sec"  if length($sec)==1;
			$min  = "0$min"  if length($min)==1;
			$hour = "0$hour" if length($hour)==1;
			$mday = "0$mday" if length($mday)==1;
			$mon  = "0$mon"  if length($mon)==1;

			$date = $mon."/".$mday."/".($year+1900); 
			my $time = $hour.":".$min.":".$sec;
			my $stamp = $date." ".$time;
			return $date;			
}

# Takes in a text and a time period, and keeps track how many times every word appears in it.
sub trackWords {
	my ($word, $timePeriod) = @_;
	# Converts it all to lowercase.
	$word = lc($word);
	chomp $word;
	# Total words.
	$wordCount++;
	# Counts words per period.
	$words{$word}{$timePeriod}++;
	return $word;
}


sub specialCharacters {
	my $body = shift;
	
	# get rid of links
	$body =~ s/\[(.*?)\]\( ?https?:.*?\)/$1/g; 		# [text](http://link.com)
	$body =~ s/\( ?https?:.*?\)//g; 				# (http://link.com)
	$body =~ s/http\S*?\Z/ /g; 						# end of line
	$body =~ s/http\S*?\s/ /g; 						# any other free-standing ones
	
	# All html
	$body =~ s{\&lt;}{<}g;
	$body =~ s{\&gt;}{>}g;
	$body =~ s{\&amp;}{\&}g;
	$body =~ s{\&nbsp;}{ }g;
	
	# For all other cases, just turn them into white spaces.
	$body =~ s{\&[0-9a-z]+?;}{ };
	
	# I can't get unicode to work. I'll have to remove them for now.
	$body =~ s{\\u[0-9a-g]+}{}g;	
	
	# All escape characters
	$body =~ s{\\\"}{"}g;
	$body =~ s{\\n}{ }g;
	$body =~ s{\\r}{ }g;
	$body =~ s{\\t}{ }g;
	

	return $body;
}

# Add commas to numbers larger than 1000.
sub addCommas {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}
