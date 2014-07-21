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
    my ($class,$action) = @_;
    my $self = $class->SUPER::new();

    $self->data($action);
    return $self;
}

sub name {
    my $self = shift;
    return $self->data()->getname();
}

sub children {
    my $self = shift;

    # TODO - get all args, not just direction=in
    my @arguments = $self->data()->argumentlist_in();

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

    # TODO - check that all our children have args
    # TODO - construct action post
    # TODO - return args

    # HACK, WTF, FIXME - why is this wrapped in an Array
    my $service = ($self->parent()->parent()->data())[0];

    my $action_res = $service->postaction($self->name());

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

1;
