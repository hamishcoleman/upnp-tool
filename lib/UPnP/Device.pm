package UPnP::Device;
use warnings;
use strict;
#
# Represent a devince
#

use base qw(HC::Tree::Node);
use HC::Net::UPnP::Service;
use UPnP::ServiceType;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->data(@_);
    return $self;
}

sub name {
    my $self = shift;
    my $device = $self->data();
    return $device->getdevicetype();
}

sub children {
    my $self = shift;
    my $device = $self->data();

    my @services = HC::Net::UPnP::Service->import($device->getservicelist());

    # Separate in to same-typed items
    my %types;
    for my $service (@services) {
        push @{$types{$service->getservicetype()}},$service;
    }

    my @children;
    for my $servicetype (values %types) {
        my $node = UPnP::ServiceType->new(@{$servicetype});
        $node->parent($self);
        push @children, $node;
    }
    return @children;
}

sub to_string_verbose {
    my $self = shift;
    return $self->data()->getlocation();
}

1;
