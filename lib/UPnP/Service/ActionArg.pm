package UPnP::Service::ActionArg;
use warnings;
use strict;
#
# Represent one of the Args for an Action
#

use base qw(HC::Tree::Node);

sub new {
    my ($class,$arg) = @_;
    my $self = $class->SUPER::new();

    $self->data($arg);
    return $self;
}

sub name {
    my $self = shift;
    return $self->data();
}

#direction in or out ?

#sub set val ?

1;
