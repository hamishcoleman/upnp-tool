package UPnP::Service::StateTable;
use warnings;
use strict;
#
# Represent the list of Actions available
#

use base qw(HC::Tree::Node);

sub new {
    my ($class,$service) = @_;
    my $self = $class->SUPER::new();

    $self->data($service);
    return $self;
}

sub name {
    my $self = shift;
    return "StateTable";
}

#sub children {
#    my $self = shift;
#
#    my @children;
#    push @children, UPnP::ServiceActionList->new($service);
##    push @children, UPnP::ServiceStateTable->new($service);
#
#    return @children;
#}

1;
