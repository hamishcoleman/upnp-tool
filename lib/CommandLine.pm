package CommandLine;
use warnings;
use strict;

use UPnP::Network;

use Data::Dumper;

our $VERBOSE = 0;

sub HANDLE {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    # TODO - figure out a nicer hack than this for verbose mode
    $HC::Tree::Node::VERBOSE=$VERBOSE;

    my @searchpath;
    my %args;
    for my $i (@_) {
        if ($i =~ m/^http/) {
            # Sometimes we use http urls instead of searchpaths
            push @searchpath,$i;
        } elsif ($i =~ m/^([^=]+)=(.*)$/) {
            # Args have the format "key=val"
            $args{$1}=$2;
        } else {
            # the named searchpath does not
            push @searchpath,$i;
        }
    }

    my $t = UPnP::Network->new();

    my @nodes = $t->search(@searchpath);

    for my $node (@nodes) {
        next if (!defined($node));
        print $node->to_string_treenode();

        # if we have dug deep enough ..
        if ($node->can('call')) {
            # TODO - define a "set" on the ActionArgs object and use that
            # instead of passing the args to call
            $node->call(%args);
        }
    }
}


1;

