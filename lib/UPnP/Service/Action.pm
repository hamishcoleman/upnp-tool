package UPnP::Service::Action;
use warnings;
use strict;
#
# Represent an Actions
#

use base qw(HC::Tree::Node);
use UPnP::Service::ActionArg;

use Data::Dumper;

sub new {
    my ($class,$xml) = @_;
    my $self = $class->SUPER::new();

    $self->data($xml);
    return $self;
}

sub name {
    my $self = shift;
    return $self->_getdescription(name => 'name');
}

sub children {
    my $self = shift;

    # TODO - get all args, not just direction=in
    my @arguments = $self->_argumentlist_in();

    my @children;
    for my $arg (@arguments) {
        next if (!defined($arg));
        my $node = UPnP::Service::ActionArg->new($arg);
        $node->parent($self);
        push @children, $node;
    }

    return @children;
}

# Make an RPC call to the action described by $self
sub call {
    my $self = shift;
    my %args = (
        @_,
    );

    # TODO - check the direction of the arg (in or out) ?
    for my $child ($self->children()) {
        if (!defined($args{$child->name()})) {
            # we are missing an arg, bail out
            return undef;
        }
    }

    # TODO - check that all our children have args
    # TODO - construct action post
    # TODO - return args

    # HACK, WTF, FIXME - why is this wrapped in an Array
    my $service = ($self->parent()->parent()->data())[0];

    my $action_res = $service->postaction($self->name(),\%args);

    if ($action_res->getstatuscode() != 200) {
        printf("\n\nERROR: %i\n\n%s\n",
            $action_res->getstatuscode(),
            $action_res->getcontent(),
        );
        return 0;
    }

    print("\nResults:\n");
    print(Dumper($action_res->getargumentlist()));
}

# This is inherited from the style used throughout Net::UPnP
# FIXME - should just use an XML parser, which would replace this
sub _getdescription {
    my($self) = shift;

    my %args = (
        name => undef,
        @_,
    );
    if ($args{name}) {
        unless ($self->data() =~ m/<$args{name}>(.*?)<\/$args{name}>/i) {
            return '';
        }
        return $1;
    }
    return $self->data();
}

sub _argumentlist_in {
    my($self) = shift;

    my $description = $self->data();
    if ($description !~ m/<argumentlist>(.*?)<\/argumentlist>/sgi) {
        return undef;
    }
    my $argumentlist = $1;

    my @argumentlist_in = qw();
    while ($argumentlist =~ m/<argument>(.*?)<\/argument>/sgi) {
        my $arg = $1;
        my ($dir) = $arg =~ m/<direction\s*>(.*?)<\/direction>/i;
        next if ($dir ne 'in');
        my ($name) = $arg =~ m/<name>(.*?)<\/name>/sgi;
        push @argumentlist_in,$name;
    }
    return @argumentlist_in;
}


1;
