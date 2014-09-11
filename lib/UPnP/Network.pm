package UPnP::Network;
use warnings;
use strict;
#
# Represent an entire UPnP network
#

use base qw(HC::Tree::Node);

use Net::UPnP::Device;

use Net::UPnP::ControlPoint;
use UPnP::NamedDevice;
use LWP::UserAgent;
use Storable;
use File::Spec;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    # TODO - config args

    # For now, we are just using the Net::UPnP libraries
    $self->{ControlPoint} = Net::UPnP::ControlPoint->new();
    $self->name($class);
    
    return $self;
}

# A quick set of hacky routines to cache data
# - TODO - this lookw like a good candidate for generalising into a lib

sub _cachefile_name {
    my ($self) = @_;
    return File::Spec->catdir($ENV{'HOME'},'.upnp.network.cache');
}

sub _cachefile_validate {
    my ($self) = @_;
    my $mtime = (stat($self->_cachefile_name()))[9];
    if (!defined($mtime)) {
        return 0;
    }
    my $age = time() - $mtime;
    # FIXME - use the "CACHE-CONTROL:" ssdp header to gauge validity
    if ($age < 300) {
        return 1;
    } else {
        return 0;
    }
}

sub _cachefile_load {
    my ($self) = @_;
    return retrieve($self->_cachefile_name());
}

sub _cachefile_save {
    my ($self,$data) = @_;
    store($data,$self->_cachefile_name());
}

# HACK!
# look at the description and try to fixup any possible chunked transfer
# encoding.  The HTTP library used by Net::UPnP does not support it and
# has just passed it through unaltered - yuk!
sub _HACK_fix_chunks {
    my ($device) = @_;

    return if ($device->getdescription() !~ m/^[0-9a-f]+\r\n/i);

    my $old_description = $device->getdescription();
    my $new_description = '';

    while ($old_description) {
        if ($old_description =~ s/^([0-9a-f]+)\r\n//i) {
            $new_description.= substr($old_description,0,hex($1),'');
            substr($old_description,0,2,''); # remove the final crnl
        } else {
            die("Could not apply hack to fix chunked encoding");
        }
    }
    $device->setdescription($new_description);
}

# FIXME
# - we could ask the controlpoint to filter based on the upstream search terms
#   but that would probably require layer violations.  With caching, it is not
#   too bad
#
sub children {
    my $self = shift;

    # Quick cache
    # TODO - cache expiry
    if (defined($self->{children})) {
        return @{$self->{children}};
    }

    my @unfiltered;

    if ($self->_cachefile_validate()) {
        @unfiltered = @{$self->_cachefile_load()};
    } else {
        # First, get a list that probably contains duplicates
        eval {
            $SIG{PIPE} = 'IGNORE';
            # if the broadcast packets have an invalid LOCATION in them then we
            # end up with a SIGPIPE, which normally kills perl.
            # FIXME - spit out an error message if this occurs
            @unfiltered = $self->{ControlPoint}->search();
        };
        $self->_cachefile_save(\@unfiltered);
    }

    # then deduplicate the list on the control location
    my %seen;
    for my $device (@unfiltered) {
        $seen{$device->getlocation()} = $device;
    }
    my @devices = values(%seen);

    for my $device (@devices) {
        _HACK_fix_chunks($device);
    }

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

    my $ua = LWP::UserAgent->new;
    $ua->agent(ref($self)."/0.1");
    my $res = $ua->get($url);

    if (!$res->is_success) {
        warn $res->status_line;
        return undef;
    }

    if ($res->header('x-died')) {
        # My Samsung Optical drive claims "transfer-encoding: chunked" when
        # in fact it is not, causing an error like this.

        # Let the user know that something horrid is going on..
        warn($res->header('x-died')."\n");
        warn("WARNING: Looks like a broken device at $url");
        return undef;
    }

    my $dev = Net::UPnP::Device->new();
    $dev->setssdp( "LOCATION: $url\r\n" );
    $dev->setdescription($res->decoded_content());

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
    if (!defined($device)) {
        return undef;
    }
    $node = UPnP::NamedDevice->new($device);
    $node->parent($self);

    if (scalar(@_) > 0) {
        # there is more searching to be done
        return $node->search(@_);
    }

    return $node;
}

1;
