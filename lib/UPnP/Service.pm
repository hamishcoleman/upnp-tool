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
    return $self->getscpdurl();
}

# No, really, relative paths are not useful urls..
# so, convert to a full url
sub getscpdurl {
    my ($self) = shift;
    my $service = $self->data();

    my $baseurl = URI->new($service->getdevice()->getlocation());
    my $scpdurl = URI->new($service->getscpdurl());
    return $scpdurl->abs($baseurl);
}

# Fetch the SCPD for this endpoint
sub getscpd {
    my ($self) = shift;

    if (defined($self->{scpd})) {
        return $self->{scpd};
    }

    my $scpdurl = $self->getscpdurl();

    my $ua = LWP::UserAgent->new;
    $ua->agent(ref($self)."/0.1");
    my $res = $ua->get($scpdurl);

    if (!$res->is_success) {
        warn $res->status_line;
        return undef;
    }

    # TODO - check and return errors?

    $self->{scpd} = $res->decoded_content();
    return $self->{scpd};
}


1;
