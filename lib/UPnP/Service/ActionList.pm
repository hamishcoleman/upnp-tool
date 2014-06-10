package UPnP::Service::ActionList;
use warnings;
use strict;
#
# Represent the list of Actions available
#

use base qw(HC::Tree::Node);
use UPnP::Service::Action;

sub new {
    my ($class,$service) = @_;
    my $self = $class->SUPER::new();

    $self->data($service);
    return $self;
}

sub name {
    my $self = shift;
    return "Action";
}

sub children {
    my $self = shift;

    my @actions = $self->data()->actionlist();
    my @children;
    for my $action (@actions) {
        my $node = UPnP::Service::Action->new($action);
        $node->parent($self);
        push @children, $node;
    }

    return @children;
}

1;
