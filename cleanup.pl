#!/usr/bin/perl

##### NOTE! The month formatting is lost here! Try to fix it before running this again! ###

# This script takes in a raw file from Reddit and cleans it up.
# It strips away everything except the datetime, user, and text.
# It then saves this into another file.

# It does this to every nth line (default=1000) in order to reduce the sample size.
# This program's output feeds into combine.pl and words.pl.

use strict;
use warnings;
use feature 'say';
use utf8;

my $file = "RC_2007-10";

#my $totalLines = &countLines($file);

open IN,  "<input/$file" or die "Cannot open $file: $!";
open OUT, ">input/$file"."_clean.txt";

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
	next unless $lineNum % 1000 == 0;
	
	
	# Extract just the text
	m/\{.*"body":"(.*?)(?<!\\)"(,.*)?\}/;
	my $body = $1;
	next unless $body;
	
	
	# Extract the DT stamp
	# "created_utc":1438272000,
	# "created_utc":1438272000    # no comma if at the end
	# "created_utc":"1438272000"  # some files have quote around the numbers
	#m/\{.*"created_utc":"(\d+?),.*\}/;
	m/\{.*"created_utc":"?(\d+)"?,?.*\}/;
	my $dt = $1;
	
	
	# Convert DT stamp into a readable format
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($dt);
	
	$sec  = "0$sec"  if length($sec)==1;
	$min  = "0$min"  if length($min)==1;
	$hour = "0$hour" if length($hour)==1;
	$mday = "0$mday" if length($mday)==1;
	$mon  = "0$mon"  if length($mon)==1;
	
	# The month formatting is lost here because of the ($mon+1) in the my $date statement.
	# Next time, try putting $mon+1 before these six formatting lines.
	
	my $date = ($mon+1)."/".$mday."/".($year+1900); # The months are off for some reason
	my $time = $hour.":".$min.":".$sec;
	my $stamp = $date." ".$time;


	# Translate coded text
	$body = &specialCharacters($body);
	next if $body =~ /\A\s*\Z/; # If there's nothing left, junk it.

	say OUT "$date\t$time\t$author\t$body";
	#say OUT $body;
	
	
	$body =~ s/\w+/$wordCount++/ge;
}
say "\t\t\tDone.";

say "Found $wordCount words";

close IN;
close OUT;


sub countLines {

}


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