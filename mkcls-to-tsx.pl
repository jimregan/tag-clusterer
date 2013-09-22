#!/usr/bin/perl

use warnings;
use strict;

my %single = ();
my %mult = ();

sub classname {
	my $clsname = $_[0];
	# some conventions
	$clsname =~ s/<n><acr>/ACRONIMO/;
	$clsname =~ s/<n>/NOM/;
	$clsname =~ s/<vblex>/VB/;
	$clsname =~ s/<ij>/INTERJ/;
	$clsname =~ s/<np><al>/NPALTRES/;
	$clsname =~ s/<np><ant>/ANTROPONIM/;
	$clsname =~ s/<np><top>/TOPONIM/;
	$clsname =~ s/<np><loc>/TOPONIM/;

	#rest
	$clsname = uc $clsname;
	$clsname =~ s/[<>]//g;
	return $clsname;
}

my %simple = ();
my %closed = ();

while (<>) {
	chomp;
	my ($tag, $class) = split/\t/;
	next if ($tag eq 'UNK');
	next if ($tag =~ /^\*/);
	if ($tag =~ /\+/) {
		push @{$mult{$class}}, $tag;
	} else {
		push @{$single{$class}}, $tag;
	}
}

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<tagger name=\"generated\">\n";
print "  <tagset>\n";

for my $k (keys %single) {
	my $lemma = 0;
	my $tagsout = "";
	my $clsname = "CLASS$k";
	my $lemtmp = "";

	# in simple cases, we can name it a little better
	if ($#{$single{$k}} == 0) {
		$clsname = classname (${$single{$k}}[0]);
		# '$simple{${$single{$k}}[0]}' is part of why people hate Perl :)
		# this is a tags-to-name hash, for use later in def-mults
		$simple{${$single{$k}}[0]} = $clsname;
	}
	for my $v (@{$single{$k}}) {
		$tagsout .= "      <tags-item ";
		if ($v =~ /^([^<]*)</ && $1 ne '') {
			$lemtmp = $1;
			$lemtmp =~ s/_/ /g;
			$tagsout .= "lemma=\"$lemtmp\" ";
			$v =~ s/^([^<]*)</</;
			$lemma = 1;
		}
		$v =~ s/></./g;
		$v =~ s/[<>]//g;
		$tagsout .= "tags=\"$v\"/>\n";
	}
	print "    <def-label name=\"$clsname\"";
	if ($lemma == 1) {
		print " closed=\"true\"";
		$closed{$clsname} = 1;
	}
	print ">\n";
	print $tagsout;
	print "    </def-label>\n";
}

for my $m (keys %mult) {
	my $lemma = 0;
	my $tagsout = "";
	# Stuck with sucky names for def-mults for now.
	my $clsname = "MULT$m";
	my $lemtmp = "";

	for my $v (@{$mult{$m}}) {
		$tagsout .= "      <sequence>\n";
		for my $s (split(/\+/, $v)) {
			if (exists $simple{$s}) {
				$tagsout .= "        <label-item label=\"$simple{$s}\"/>\n";
				if ($closed{$simple{$s}} && $closed{$simple{$s}} == 1) {
					$lemma = 1;
				}
			} else {
				$tagsout .= "        <tags-item ";
				if ($s =~ /^([^<]*)</ && $1 ne '') {
					$lemtmp = $1;
					$lemtmp =~ s/_/ /g;
					$tagsout .= "lemma=\"$lemtmp\" ";
					$s =~ s/^([^<]*)</</;
					$lemma = 1;
				}
				$s =~ s/></./g;
				$s =~ s/[<>]//g;
				$tagsout .= "tags=\"$s\"/>\n";
			}
		}
		$tagsout .= "      </sequence>\n";
	}
	
	print "    <def-mult name=\"$clsname\"";
	if ($lemma == 1) {
		print " closed=\"true\"";
	}
	print ">\n";
	print $tagsout;
	print "    </def-mult>\n";
}

print "  </tagset>\n";
print "</tagger>\n";
