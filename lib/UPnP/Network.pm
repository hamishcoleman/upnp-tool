package UPnP::Network;
use warnings;
use strict;
#
# Represent an entire UPnP network
#

use base qw(HC::Tree::Node);

use HC::Net::UPnP::ControlPoint;
use UPnP::NamedDevice;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    # TODO - config args

    # For now, we are just using the Net::UPnP libraries
    $self->{ControlPoint} = HC::Net::UPnP::ControlPoint->new();
    $self->name($class);
    
    return $self;
}

# FIXME
# - this queries the entire network, we could filter based on needs
sub children {
    my $self = shift;

    # Quick cache
    # TODO - cache expiry
    if (defined($self->{children})) {
        return @{$self->{children}};
    }

    my @devices;
    @devices = $self->{ControlPoint}->getfiltereddevices();

    # Separate in to same-named items
    my %names;
    for my $device (@devices) {
        push @{$names{$device->getfriendlyname()}},$device;
    }

    my @children;
    for my $name (values %names) {
        my $node = UPnP::NamedDevice->new(@{$name});
        $node->parent($self);
        push @children, $node;
    }
    @{$self->{children}} = @children;
    return @children;
}

sub search {
    my $self = shift;
    my $filter = shift;

    my $node;
    if (($filter||'') !~ m/^http/) {
        # a normal search, just pass on to the parent class
        return $self->SUPER::search($filter,@_);
    }

    my $device = $self->{ControlPoint}->getdevicebyurl($filter);
    $node = UPnP::Device->new($device);
    $node->parent($self);

    if (scalar(@_) > 0) {
        # there is more searching to be done
        return $node->search(@_);
    }

    return $node;
}

1;
