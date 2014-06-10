package UPnP::ServiceType;
use warnings;
use strict;
#
# Represent a type of service
#

use base qw(HC::Tree::Node);
use UPnP::Service;

sub new {
    my ($class,@services) = @_;
    my $self = $class->SUPER::new();

    $self->_add_services(@services);    
    return $self;
}

sub _add_services {
    my ($self,@services) = @_;

    my $name = $services[0]->getservicetype();

    for my $service (@services) {
        if ($service->getservicetype() ne $name) {
            # Someone is trying to slip us a micky
            # TODO - dont just die
            die "mismatched typed service $name";
        }
    }
    $self->name($name);

    $self->data(\@services);

    return $self;
}

sub children {
    my $self = shift;

    # HACK! WTF!
    # Somehow, the data field ends up as an array of array of ServiceTypes
    # I expect the above to make it an array of ServiceTypes
    my $data1 = $self->data();
    my @data2 = @{$data1};

    my @children;
    for my $service (@data2) {
        my $node = UPnP::Service->new($service);
        $node->parent($self);
        push @children, $node;
    }
    return @children;
}

1;
