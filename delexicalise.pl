#!/usr/bin/perl

use warnings;
use strict;

while(<>) {
	chomp;
	# Trim leading & tailing whitespace
	s/^\s*//;
	s/\s*$//;

	if (/^$/) {
		print "\n";
		next;
	}

	# This is supposed to be one token per line,
	# so dump the begin and end markers and check for them
	s/^\^//;
	s/\$$//;
	die "Input should be one token per line" if (/[\^\$]/);

	# Throw away any escaped slashes
	s/\\\///;

	# 
	if (/\^\*/) {
		print "UNK\n";
		next;
	}

	# We only care about the analysis
	my @parts = split/\//;
	die "Untagged text, cannot continue (text was: $_)" if ($#parts != 1);
	$_ = $parts[1];

	#And now we delexicalise (=throw anything that's not a tag)
	s/^([^<]*)//;
	s/>\+([^<]*)</>+</g;
	s/([^>]*)$//;

	print "$_\n";
}
