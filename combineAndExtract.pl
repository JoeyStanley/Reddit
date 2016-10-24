#usr/bin/perl

# This program takes in all files in a directory and combines them into one big file.
# The files should be already processed by cleanup.pl
# This program's output is fed into words.pl.
# NOTE: The input and output files should not be in the same directory or else it will read in the output and loop forever until you run out of hard drive space.

# Code taken from http://stackoverflow.com/questions/5651659/read-all-files-in-a-directory-in-perl

use strict;
use warnings;
use feature 'say';

my $dir = "/Volumes/Joey1TB/Research/Reddit/100th";
die $! unless -e $dir;

# Output file
open OUT, ">/Volumes/Joey1TB/Research/Reddit/reddit_100_clean.txt";

my $totalWordCount = 0;
# Go through each file in the directory.
foreach my $fp (glob("$dir/*.txt")) {
  	say $fp;
	open my $fh, "<", $fp or die "can't read open '$fp': $_";
   
	my $wordCount = 0;
	my $lineNum = 0;
    while (<$fh>) {
      	# Count how many lines there are.
      	$lineNum++; 

		#----------------------------#
		#  Get upvotes and downvotes #
		#----------------------------#
		m/"downs":(\d+)/;
		my $downs = $1;
		$downs = 0 if !defined $downs;

		m/"ups":(\d+)/;
		my $ups = $1;
		$ups = 0 if !defined $ups;

		#----------------------------#
		#       Get Subreddit        #
		#----------------------------#
		m/"subreddit":"(.+?)"/;
		my $sub = $1;

		#----------------------------#
		#         Get Author         #
		#----------------------------#
		m/"author":"(.+?)"/;
		my $author = $1;

		#----------------------------#
		#       Date and Time        #
		#----------------------------#
		# Extract the DT stamp
		# "created_utc":1438272000,
		# "created_utc":1438272000    # no comma if at the end
		# "created_utc":"1438272000"  # some files have quote around the numbers
		#m/\{.*"created_utc":"(\d+?),.*\}/;
		m/\{.*"created_utc":"?(\d+)"?,?.*\}/;
		my $dt = $1;

		# Convert DT stamp into a readable format
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($dt);
		$mon++; # The months are off for some reason

		$sec  = "0$sec"  if length($sec)==1;
		$min  = "0$min"  if length($min)==1;
		$hour = "0$hour" if length($hour)==1;
		$mday = "0$mday" if length($mday)==1;
		$mon  = "0$mon"  if length($mon)==1;

		# The month formatting is lost here because of the ($mon+1) in the my $date statement.
		# Next time, try putting $mon+1 before these six formatting lines.

		my $date = $mon."/".$mday."/".($year+1900); 
		my $time = $hour.":".$min.":".$sec;
		my $stamp = $date." ".$time;

		#----------------------------#
		#            Body            #
		#----------------------------#
	
		# Extract just the text (Saved until end because it's the biggest)
		m/\{.*"body":"(.*?)(?<!\\)"(,.*)?\}/;
		my $body = $1;
		next unless $body;

		# Translate coded text
		$body = &specialCharacters($body);
		next if $body =~ /\A\s*\Z/; # If there's nothing left, junk it.

		#----------------------------#
		#           Print            #
		#----------------------------#
		say OUT "$date\t$time\tSub: $sub\tAuthor: $author\tUps: $ups\tDowns: $downs\t$body";

		# Count the words
		$body =~ s/\w+/$wordCount++; $&/ge;
    }
    
    # For my own sake, see how many lines and words.
    say "\t".(addCommas($lineNum))." lines and ".(addCommas($wordCount))." words.";
	$totalWordCount += $wordCount;
	say "\tUp to ", (addCommas($totalWordCount))." total words at this point.";

  close $fh or die "can't read close '$fp': $_";
}

close OUT;


sub specialCharacters {
	my $body = shift;
	
	# get rid of html
	$body =~ s/\[(.*?)\]\( ?https?:.*?\)/$1/g; # [text](http://link.com)
	$body =~ s/\( ?https?:.*?\)//g; # (http://link.com)
	$body =~ s/http\S*?\Z/ /g; # end of line
	$body =~ s/http\S*?\s/ /g; # any other free-standing ones
	
	# All htlm coding
	$body =~ s{\&lt;}{<}g;
	$body =~ s{\&gt;}{>}g;
	$body =~ s{\&amp;}{\&}g;
	$body =~ s{\&nbsp;}{ }g;
	#$body =~ s{\&emdash;}{—}g;
	
	# For all other cases, just turn them into white spaces.
	$body =~ s{\&[0-9a-z]+?;}{ };
	#$body =~ s{\&[0-9a-z]+?;}{say $&; " "}ge;
	
	# I can't get unicode to work. I'll have to remove them for now.
	$body =~ s{\\u[0-9a-g]+}{}g;
	#$body =~ s{\\u([0-9a-g]+)}{"\x{$1}"}gei;
	
	
	# All escape characters
	$body =~ s{\\\"}{"}g;
	$body =~ s{\\n}{ }g;
	$body =~ s{\\r}{ }g;
	
	return $body;
}

sub addCommas {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}