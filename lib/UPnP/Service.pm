package UPnP::Service;
use warnings;
use strict;
#
# Represent a service
#

use base qw(HC::Tree::Node);
use UPnP::Service::ActionList;
use UPnP::Service::StateTable;

sub new {
    my ($class,$service) = @_;
    my $self = $class->SUPER::new();

    $self->data($service);
    return $self;
}

sub name {
    my $self = shift;
    my $service = $self->data();
    return $service->getserviceid();
}

sub children {
    my $self = shift;

    # HACK, WTF, FIXME - why is this wrapped in an Array
    my $service = ($self->data)[0];

    my @children;
    my $actionlist = UPnP::Service::ActionList->new($service);
    $actionlist->parent($self);

    my $statetable = UPnP::Service::StateTable->new($service);
    $statetable->parent($self);

    push @children, $actionlist, $statetable;

    return @children;
}

sub to_string_verbose {
    my $self = shift;
    return ($self->data())[0]->getscpdurl_real();
}

1;
