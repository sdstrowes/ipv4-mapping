#!/usr/bin/perl

BEGIN {push @INC, '~/proj/ipv4-mappings/occupancy/'}

use strict;
use warnings;
use diagnostics;

use Getopt::Long;
use IanaMappings qw(%Iana_Region);
use NetAddr::IP;

my $verbose = 0;
GetOptions ('verbose' => \$verbose);

if ($verbose) {
	print "reading...\n";
}

my $n = 0;
my %space_hash = ();
while (<>) {
	# This isn't smart, but take every single prefix, break it into /24s, and store each /24.
	my @blocks = NetAddr::IP->new($_)->split(24);
	for my $block (@blocks) {
		$space_hash{$block} = 1;
	}
	$n += 1;
	if ($verbose && $n % 1000 == 0) {
		print $n,"\n";
	}
}

if ($verbose) {
	print "mashing...\n";
}
my %occupancy = ();
for my $slash_eight (0 .. 255) {
	$occupancy{$slash_eight} = 0;
}
# For each /24, determine the /8 it belongs to, and increment.
# Each /8 has 2^16 /24s, so measuring occupancy is a simple matter of counting.
for my $block (keys %space_hash) {
	my $slash_eight = int((split(/[.]/, $block, 4))[0]);
	$occupancy{$slash_eight} += 1;
}

# Having counted, run through each /8 and attribute the count to each RIR.
my $total_occupancy = 0;
my $total_blockcount = 0;
my %region_occupancy = ();
my %region_blockcount = ();
for my $slash_eight (sort {$a <=> $b} keys %occupancy) {
	if ($verbose) {
		print $slash_eight, " ", $occupancy{$slash_eight}, " ", $occupancy{$slash_eight} / 65536, "\n";
	}

	# The actual space available for public routing per /8 varies.
	# See http://www.iana.org/assignments/ipv4-address-space/
	my $space_available = 65536;
	# 100: 1x /10 unavailable
	if    ($slash_eight eq "100") {$space_available = 49152}
	# 169: 1x /16 unavailable
	elsif ($slash_eight eq "169") {$space_available = 65280}
	# 172: 1x /12 unavailable
	elsif ($slash_eight eq "172") {$space_available = 61440}
	# 192: 3x /24 and 1x /16 unavailable
	elsif ($slash_eight eq "192") {$space_available = 65277}
	# 198: 1x /15 and 1x /24 unavailable
	elsif ($slash_eight eq "198") {$space_available = 65023}
	# 203: 1x /24 unavailable
	elsif ($slash_eight eq "203") {$space_available = 65535}

	$total_occupancy  += $occupancy{$slash_eight};
	$total_blockcount += $space_available;
	$region_occupancy{$Iana_Region{$slash_eight}}  += $occupancy{$slash_eight};
	$region_blockcount{$Iana_Region{$slash_eight}} += $space_available;
}

for my $region (sort keys %region_occupancy) {
	print $region, "\t", ($region_occupancy{$region}/$region_blockcount{$region})*100,"\t",$region_occupancy{$region},"\n";
}
print "TOTAL\t",($total_occupancy/$total_blockcount)*100,"\t",$total_occupancy,"\n";
