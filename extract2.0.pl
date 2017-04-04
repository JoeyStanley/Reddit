#!/usr/bin/perl
# Step 1 of processing Reddit files.
# This file reads in all Reddit files and turns them into a tab-delimited .txt file. 
# Only extracts the date, time, subreddit, author, upvotes, downvotes, and text.
# Written by Joey Stanley. Altered by Barry Shelton
# August 15, 2015/Feb. 2017
use strict;
use warnings;
use feature 'say';
use diagnostics; 
use Parallel::ForkManager;
use Benchmark::Timer;
use Fcntl qw(:flock SEEK_END);
my $start = time;														#Set start time for Benchmarking
my $dir = "./";
my $pattern = 'pa[tt]{2}ern'; 											#Just Change Your Patterns here. n.b. Escape 2X in quoted strings
my $of = "$dir/output/IsNotAWord.txt";									# Output file
my $Nforks = 6;															# Set # of Parallel Forks
my $fm = Parallel::ForkManager->new($Nforks);
my $wordCount;
my $matches;
my $lineNum;
my $nth = 1;															# Processes Files on $nth line--for percentage-wise subsetting.
my @fps = (glob("$dir/JSON/*"));  										#Glob in array of Files
die $! unless -e $dir;
open OUT, ">> $of" or die "can't open outfile"; 						 								 
say OUT "Date\tTime\tSubreddit\tAuthor\tText\tMatch\tRawMatch";

####################
####Main Routine####
####################

foreach (my $i = 0; $i < @fps; $i++) {  								#Set iterator for forks
	
	$fm->start and next;												#Start forking
	ParseJSON ($fps[$i]);												#Call to subs on array of files
	my $duration = time - $start;
	if ($duration > 3600){
		$duration = $duration / 3600;        		 					#Benchmarking and Runtime
		say "\tI've been running for $duration hours now";
			}elsif($duration > 60){	
				$duration = $duration / 60;        
				say "\tI've been running for $duration minutes now";
			}else{
				say "\tI've been running for $duration seconds now";
			}								
	$fm->finish;
	}

$fm-> wait_all_children;
close OUT;

################
####Main Sub####
################
sub ParseJSON {
  	my $fp = shift;
	open my $fh, "<", $fp or die "can't read open '$fp': $_";										
	$wordCount = 0;
	$lineNum = 0;
	$matches = 0;
    while (<$fh>) {      	
      	$lineNum++;   													#Count how many lines there are.   	
		next unless $lineNum % $nth == 0;  								#if match process body
		if ($_ =~ m/($pattern)/i){										#Get matches
			$matches++;
			my $body = $1;					
			my $rawmatch = &specialCharacters($body); 					#Sub on $rawmatch
			my $match = lc $rawmatch;									#Clean up $rawmatch
			$match =~ s/ {2,}/ /g;
			$match =~ s/[[:punct:]]//g; 

		
			#----------------------------#
			#  Get upvotes and downvotes #
			#----------------------------#
			#~ m/"downs":(\d+)/;										#Sometimes ups and downs get screwy when grepping $1
			#~ my $downs = $1;											#Since I didn't need them, I just commented the function in this version.
			#~ $downs = 0 if !defined $downs;
			#~ m/"ups":(\d+)/;
			#~ my $ups = $1;
			#~ $ups = 0 if !defined $ups;

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
			m/\{.*"created_utc":"?(\d+)"?,?.*\}/;
			my $dt = $1;

			# Convert DT stamp into a readable format
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($dt);
			$mon++; 

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
			$body = $1;
			next unless $body;

			# Transcode html & strip links 
			$body = &specialCharacters($body);
			next if $body =~ /\A\s*\Z/; # If there's nothing left, junk it.

			#----------------------------#
			#           Print            #
			#----------------------------#
			flock OUT, LOCK_EX or die "Cannot lock - $!\n";;				#Lock OUT so forks don't collide on "say"
			seek OUT, 0, SEEK_END or die "Cannot seek - $!\n";				#Make sure we're appending, in case another fork wrote while this one was waiting
			say OUT "$date\t$time\t$sub\t$author\t$body\t$match\t$rawmatch";
			flock OUT, LOCK_UN or die "Cannot unlock - $!\n";;				#unlock OUT 
			# Count the words
			$body =~ s/\w+/$wordCount++; $&/ge;
																			
		}
	
	}
    
   
    say "Finished with $fp";
    say "\tThere were $lineNum lines in $fp";
    say "\tI found $matches matches in $fp.";
    say "\tI extracted $wordCount words from $fp.";
	close $fh or die "can't read close '$fp': $_";
	return ($wordCount, $lineNum);
}
# Strips unruly chars.
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
