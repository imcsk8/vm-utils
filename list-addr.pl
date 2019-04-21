#!/usr/bin/perl -w

use strict;
use XML::XPath;
use XML::XPath::XMLParser;
use Sys::Virt;

if ( ($#ARGV) > 1 and ($ARGV[1] ne "") ) {
    print "ARGV $ARGV[0]\n";
    $ENV{LIBVIRT_DEFAULT_URI} = "qemu+ssh://$ARGV[1]/system";
}
else {
    $ENV{LIBVIRT_DEFAULT_URI} = 'qemu:///system';
}




# Open libvirt connection and get the domain.
my $conn = Sys::Virt->new (readonly => 1);
my $dom = $conn->get_domain_by_name ($ARGV[0]);

# Get the libvirt XML for the domain.
my $xml = $dom->get_xml_description ();

# Parse out the MAC addresses using an XPath expression.
my $xp = XML::XPath->new (xml => $xml);
my $nodes = $xp->find ("//devices/interface[\@type='network']/mac/\@address");
my $node;
my @mac_addrs;
foreach $node ($nodes->get_nodelist) {
    print "NODE: " . $node->getData . "\n";
    push @mac_addrs, lc ($node->getData)
}

# Look up the MAC addresses in the output of 'arp -an'.
my @arp_lines = split /\n/, `arp -an`;
foreach (@arp_lines) {
    if (/\((.*?)\) at (.*?) /) {
        my $this_addr = lc $2;
        if (list_member ($this_addr, @mac_addrs)) {
            print "$1\n";
        }
    }
}

sub list_member
{
    local $_;
    my $item = shift;
    foreach (@_) {
        return 1 if $item eq $_;
    }
    return 0;
}
