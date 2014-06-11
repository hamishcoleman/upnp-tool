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

    $HC::Tree::Node::VERBOSE=$VERBOSE;

    my $t = UPnP::Network->new();

    my @nodes = $t->search(@_);

    for my $node (@nodes) {
        next if (!defined($node));
        print $node->to_string_treenode();

        # if we have dug deep enough ..
        if ($node->can('call')) {
            # TODO - load kwargs from commandline
            $node->call();
        }
    }
}


1;

