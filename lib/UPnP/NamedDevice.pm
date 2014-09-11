package UPnP::NamedDevice;
use warnings;
use strict;
#
# Represent just devices with the same name
#

use base qw(HC::Tree::Node);
use UPnP::Device;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    return $self->_add_devices(@_);    
}

sub _add_devices {
    my $self = shift;
    return if (!scalar(@_));

    my $devices;
    push @{$devices}, @_;

    my $name = $devices->[0]->getfriendlyname();
    if (!$name) {
        warn ("could not getfriendlyname!");
    }

    for my $device (@{$devices}) {
        if ($device->getfriendlyname() ne $name) {
            # Someone is trying to slip us a micky
            # TODO - dont just die
            die "mismatched named devices $name and $device->getfriendlyname()";
        }
    }

    $self->name($name);
    $self->data($devices);

    return $self;
}

sub children {
    my $self = shift;

    my $devices = $self->data();
    my @children;
    for my $device (@{$devices}) {
        my $node = UPnP::Device->new($device);
        $node->parent($self);
        push @children, $node;
    }
    return @children;
}

1;
