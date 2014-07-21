package UPnP::Network;
use warnings;
use strict;
#
# Represent an entire UPnP network
#

use base qw(HC::Tree::Node);

use Net::UPnP::HTTP;
use Net::UPnP::Device;

use Net::UPnP::ControlPoint;
use UPnP::NamedDevice;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    # TODO - config args

    # For now, we are just using the Net::UPnP libraries
    $self->{ControlPoint} = Net::UPnP::ControlPoint->new();
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

    # First, get a list that probably contains duplicates
    my @unfiltered = $self->{ControlPoint}->search();

    # then deduplicate the list on the control location
    my %seen;
    for my $device (@unfiltered) {
        $seen{$device->getlocation()} = $device;
    }
    my @devices = values(%seen);

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

sub _url2device {
    my ($self,$url) = @_;

    # FIXME - just use normal http libraries!

    my $http_req = Net::UPnP::HTTP->new();

    return undef if ($url !~ m/http:\/\/([0-9a-z.]+)[:]*([0-9]*)\/(.*)/i);

    my $post_res = $http_req->post($1, $2, "GET", '/'.$3, "", "");

    my $post_content = $post_res->getcontent();

    my $dev = Net::UPnP::Device->new();
    $dev->setssdp( "LOCATION: $url\r\n" );
    $dev->setdescription($post_content);

    return $dev;
}


sub search {
    my $self = shift;
    my $filter = shift;

    my $node;
    if (($filter||'') !~ m/^http/) {
        # a normal search, just pass on to the parent class
        return $self->SUPER::search($filter,@_);
    }

    my $device = $self->_url2device($filter);
    $node = UPnP::NamedDevice->new($device);
    $node->parent($self);

    if (scalar(@_) > 0) {
        # there is more searching to be done
        return $node->search(@_);
    }

    return $node;
}

1;
