#!/usr/bin/perl

# Step 1 of processing Reddit files.

# This script takes in a raw JSON file from Reddit and cleans it up.
# It strips away everything except the datetime, user, and text.
# It then saves this into another tab-deliminated spreadsheet file.

# This program's output feeds into combine.pl and words.pl.

use strict;
use warnings;
use feature 'say';
use utf8;

# Change this to the name of the file you want to process. This should be in a directory called
# input, which should be in the same directory as this script.
my $file = "sample.txt";
my ($name, $ext) = split(/\./, $file);

open IN,  "<JSON/$file" or die "Cannot open $file: $!";
open OUT, ">sample/$name"."_clean.txt";

# Since the corpus is so stinkin' huge, I create a subsset. The program runs by default 
# to every nth line (default=100) in order to reduce the sample size.
my $nth = 100;


my $lineNum = 0;
my $wordCount = 0;
say "Reading in $file...";
while (<IN>) {

	# Extract the user
	m/\{.*"author":"(.*?)(?<!\\)"(,.*)?\}/;
	my $author = $1;
	
	# Skip deleted comments.
	next if $author eq "[deleted]";
	
	# Only process every thousanth line
	$lineNum++;
	next unless $lineNum % $nth == 0;
	
	
	# Extract just the text
	m/\{.*"body":"(.*?)(?<!\\)"(,.*)?\}/;
	my $body = $1;
	next unless $body;
	
	
	# Extract the DT stamp. Examples: 
	# 	"created_utc":1438272000,
	# 	"created_utc":1438272000    # no comma if it's at the end
	# 	"created_utc":"1438272000"  # some files have quote around the numbers
	m/\{.*"created_utc":"?(\d+)"?,?.*\}/;
	my $dt = $1;
	
	
	# Convert DT stamp into a readable format 
	# Time stamp is in Unix Time, so Perl's built in localtime() function converts it.
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($dt);
	# (For some reason, months are stored from 0–11, and years need 1900 before them.)
	$mon = $mon+1;
	$year = $year + 1900;
	
	# Create other date time variables. 
	my $date = $mon."/".$mday."/".$year;
	my $time = $hour.":".$min.":".$sec;
	my $stamp = $date." ".$time;

	# Pad numbers with zeros if they're not two digits.
	$sec  = "0$sec"  if length($sec)==1;
	$min  = "0$min"  if length($min)==1;
	$hour = "0$hour" if length($hour)==1;
	$mday = "0$mday" if length($mday)==1;
	$mon  = "0$mon"  if length($mon)==1;

	# Translate coded text
	$body = &specialCharacters($body);
	next if $body =~ /\A\s*\Z/; # If there's nothing left, junk it.

	say OUT "$date\t$time\t$author\t$body";
	#say OUT $body;
	
	# Count the number of words.
	$body =~ s/\w+/$wordCount++/ge;
}
say "\t\t\tDone.";

say "Found $wordCount words";

close IN;
close OUT;

# This subroutine strips away unwanted characters and coding.
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