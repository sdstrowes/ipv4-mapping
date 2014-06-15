#!/usr/bin/perl

BEGIN {push @INC, '~/proj/ipv4-mappings/occupancy/'}

use strict;
use warnings;
use diagnostics;

use IanaMappings qw(%Iana_Region %Legacy_Names);

while (<>) {
	my $slash_eight = (split('\.', $_))[0];

	if (exists($Legacy_Names{$slash_eight})) {
		print $_;
	}
}
