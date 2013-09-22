#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use XML::Parser;

my $parser = XML::Parser->new(Handlers => {Start=>\&handle_start});
$parser->parsefile($ARGV[0]) or die "$!\n";

my $input;
my $reading = 0;

if($ARGV[1]) {
	open($input, "<$ARGV[1]") or die "$!\n";
} else {
	$input = *STDIN;
}
binmode $input, ":utf8";
binmode STDOUT, ":utf8";

my @tags;

while (<$input>) {
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

	# Unknown words
	if (/\^\*/ || /^\*/) {
		print "UNK\n";
		next;
	}
	my $re = '(' . join("|", @tags) . ')';
	if (/$re/) {
		my $tail = "";
		if (s/(#.*)$//) {
			$tail = $1;
		}
		s/^[^\/]*\///;
		if (/\+/) {
			my @each = split/\+/;
			my @out;
			if ($tail ne '') {
				$each[0] =~ s/^([^<]*)/$1$tail/;
			}
			for my $e (@each) {
				if ($e !~ /$re/) {
					$e =~ s/^[^<]*</</;
				}
				push @out, $e;
			}
			print join('+', @out) . "\n";
		} else {
			if (/$re/) {
				print "$_\n";
			} else {
				s/^[^<]*</</;
				print "$_\n";
			}
		}
	} else {
		s/^[^\/]*\///;
		s/^[^<]*</</;
		print "$_\n";
	}
}

sub handle_start {
	my ($expat, $element, %attrs) = @_;
	my $lemma = "";
	my $lemmatail = "";

	if ($element eq 'source') {
		$reading = 1;
	}
	if ($element eq 'lexicalized-word' && $reading) {
		if($attrs{'lemma'} && $attrs{'lemma'} ne '') {
			if ($attrs{'lemma'} =~ /#/) {
				my @parts = split/#/, $attrs{'lemma'};
				$lemmatail = '#' . pop(@parts);
				$lemma = join('#', @parts);
			} else {
				$lemma = $attrs{'lemma'};
			}
		}
		my @tmptags = split(/\./,$attrs{'tags'});
		my $regex = "";
		for my $tag (@tmptags) {
			if($tag eq '*') {
				$regex .= '(?:<[^>]*>)+';
			} else {
				$regex .= '<' . $tag . '>';
			}
		}
		push(@tags, $lemma . $regex . $lemmatail);
	}
}
