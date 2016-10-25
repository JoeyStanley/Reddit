#usr/bin/perl

# This program takes in a cleaned up file from extract.pl.
# It first goes through and saves all the words into the hash %words. 
# The hash is then printed out as words.txt, which lists how many times a particular word was used in a given time period (which must be specified), each token on its own line. 

# Written by Joey Stanley
# August 7, 2015

use strict;
use warnings;
use feature 'say';

my $file = "reddit.txt";
open IN,  "<output/$file" or die "Cannot open file: $!";
<IN>; # Read in just the first line (the header). Throw it out: we don't need it.

# If you want to track language use over time, you can track either by day or by month.
# Uncomment the one you want.
my $focus = "day";
#my $focus = "month";

# Set up some hashes and other variables.
my %words;
my $wordCount = 0;

say "Reading in file...";
while (<IN>) {
	
	# Extract each column.
	my ($date, $time, $sub, $author, $ups, $downs, $text) = split(/\t/);
	
	# First get the datatime info.
	my ($month, $day, $year) = split(/\//, $date);

	# Depending on the time frame you're interested in, it'll create a "timerPeriod" string.
	my $timePeriod = "";
	if ($focus eq "day") {
		$timePeriod = $year.'/'.$month.'/'.$day;
	} elsif ($focus eq "month") {
		$timePeriod = $month."-".$year;
	}

	# Take the body, and send it down to &trackWords(), with the date.
	# This regex here defines what a word actually is (=anything including a letter, apostrophe, or hyphen)
	$text =~ s/(\w[\w'-]*)/ trackWords($1, $timePeriod)/gei;
}

close IN;
say "\t\tDone!";
say "\t\tFound $wordCount words.";

# Takes in a text and a time period, and keeps track how many times every word appears in it.
sub trackWords {
	my ($word, $timePeriod) = @_;
	
	# Converts it all to lowercase.
	$word = lc($word);
	
	# Number of words in general.
	$wordCount++;
	
	# Track the word in that time period.
	$words{$word}{$timePeriod}++;

	# This is organized like this:
	# %lex -> word1 -> date1 = 10
	#				-> date2 = 11
	#				-> date3 = 12 
	#	   -> word2 -> date1 = 25
	#				-> date2 = 26
	#				-> date3 = 27
	#	   -> word3 -> date1 = 38
	#	 			-> date2 = 39
	#				-> date3 = 40
	
	return $word;
}


# Now that we're done with the main loop, output all this information.
say "Writing out data...";
open WORDS, ">output/words.txt";

# print them alphabetically
for my $w (sort keys %words) { 
	my $n = 0;
	
	# Go through each date and count how many times the words was there. 
	for my $date (sort keys $words{$w}) {
		$n += $words{$w}{$date};
	}
	say WORDS "$w\t$n";	
}


close WORDS;
say "\t\tDone!";