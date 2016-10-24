#usr/bin/perl

# This program takes in a cleaned up file from combine.pl (or cleanup.pl).
# It first goes through and saves all the words into the has %lex. 
# %lex is then printed out as lexemes.txt, which lists how many times a particular word was used in a given time period (which must be specified). This will then be read in and processed using an R script in the future.
# It then is printed out as counts, which simply lists each word and how many times it occurs in the entire corpus. It's listed alphabetically, which is handy to see any weird words (starting with punctuaion for example). But if opened in Excel and sorted by the frequency, it's easy to find what the most common words are.
# This prints each token on its own line. To combine them into one type per line, run the R script to_wide.R.

use strict;
use warnings;
use feature 'say';

my $file = "Reddit.txt";
#open IN,  "<input/$file" or die "Cannot open file: $!";
open IN, "/Volumes/Joey1TB/Research/Reddit/reddit_100_clean.txt" or die "Cannot open file: $!";


my %lex;
my %wordsPerTime;
my $wordCount = 0;
say "Reading in file...";
while (<IN>) {
	
	# 06/30/2015	12:00:00	username	body
	m#(.*?)\t(.*?)\t(.*?)\t(.*)\Z#;
	my ($date, $time, $user, $body) = ($1,$2,$3,$4);
	
	# First get the datatime info.
	$date =~ m#(\d+)/(\d+)/(\d+)#;
	my ($month, $day, $year) = ($1, $2, $3);
	#$time =~ m#(\d+):(\d+):(\d+)#;
	#my ($hour, $min, $sec) = ($1, $2, $3);
	#my $timePeriod = $month."-".$year;
	$month = "0$month" if length($month)==1;
	my $timePeriod = $year.'/'.$month.'/'.$day;
	
	# Take the body, and send it down to &trackWords(), with the date.
	# Defining what a word actually is is done here.
	$body =~ s/(\w[\w'-]*)/ trackWords($1, "$timePeriod")/gei;
}

close IN;
say "\t\tDone!";

# Takes in a text and a time period, and keeps track how many times every word appears in a given time period (day, month, etc.).
sub trackWords {
	my ($word, $timePeriod) = @_;
	$word = lc($word);
	
	# Number of words in general.
	$wordCount++;
	
	# Track the word in that time period.
	$lex{$word}{$timePeriod}++;
	$wordsPerTime{$timePeriod}++;
	
	return $word;
}


# Write out
say "Writing out data...";

say "\tTokens...";
open OUT, ">output/tokens.txt";
printTokens(\%lex);
close OUT;

say "\tTimes...";
open OUT, ">output/times.txt";
printTime(\%wordsPerTime);
close OUT;

say "\tWords...";
open OUT, ">output/words.txt";
printWords(\%lex);
close OUT;

say "\t\tDone!";


# Takes in a reference to a hash and prints it in a somewhat readable way.
sub printTokens {
	# Dereference
	my $ref = shift;
	my %tokens = %$ref;
	
	# Print each word and how many of each (by timePeriod).
	for my $w (sort keys %tokens) {
		#say $w;
		say OUT "$w\t".$_."\t".$tokens{$w}{$_} for sort keys $tokens{$w};	
	}
}

# Takes in a reference to a hash and prints how many 
sub printTime {
	# Dereference
	my $ref = shift;
	my %time = %$ref;
	
	# Print each word and how many of each (by timePeriod).
	for my $period (sort keys %time) {
		say OUT $period."\t".$time{$period};	
	}
}

# Prints all 500,000 unique words
sub printWords {
	# Dereference
	my $ref = shift;
	my %words = %$ref;
	
	# Print each word and how many of each (by timePeriod).
	for my $w (sort keys %words) {
		my $n = 0;
		for (sort keys $words{$w}) {
			$n += $words{$w}{$_};
		}
		say OUT "$w\t$n";	
	}
}








