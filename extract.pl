#!/usr/bin/perl

# Step 1 of processing Reddit files.

# This file reads in all Reddit files and turns them into a tab-delimited .txt file. 
# By default it only processes every 100th line because the corpus gets enormous.
# Only extracts the date, time, subreddit, author, upvotes, downvotes, and text.
# Creates a .txt file /output/reddit.txt.

# This program's output is fed into words.pl.

# Code taken from http://stackoverflow.com/questions/5651659/read-all-files-in-a-directory-in-perl

use strict;
use warnings;
use feature 'say';

# Default = this current directory. 
my $dir = "./";
die $! unless -e $dir;

# Output file
open OUT, ">$dir/output/reddit.txt";
say OUT "date\ttime\tSubreddit\tAuthor\tUps\tDowns\tText";

# By default, processes only every 100th line (to save space). 
my $nth = 100;

my $totalWordCount = 0;
# Go through each file in the directory.
foreach my $fp (glob("$dir/JSON/*.txt")) {
  	say $fp;
	open my $fh, "<", $fp or die "can't read open '$fp': $_";
  
	# Now go through each file. 
	my $wordCount = 0;
	my $lineNum = 0;
    while (<$fh>) {

      	# Count how many lines there are.
      	$lineNum++; 
		next unless $lineNum % $nth == 0;

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
		say OUT "$date\t$time\t$sub\t$author\t$ups\t$downs\t$body";

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

# Strips away weird characters.
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
	
	# For all other cases, just turn them into white spaces.
	$body =~ s{\&[0-9a-z]+?;}{ };
	
	# I can't get unicode to work. I'll have to remove them for now.
	$body =~ s{\\u[0-9a-g]+}{}g;	
	
	# All escape characters
	$body =~ s{\\\"}{"}g;
	$body =~ s{\\n}{ }g;
	$body =~ s{\\r}{ }g;
	
	return $body;
}

# Add commas to numbers larger than 1000.
# From the 'Perl Cookbook' (pages 64-65).
sub addCommas {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}