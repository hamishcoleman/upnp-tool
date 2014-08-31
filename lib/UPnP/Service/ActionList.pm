package UPnP::Service::ActionList;
use warnings;
use strict;
#
# Represent the list of Actions available
#

use base qw(HC::Tree::Node);
use UPnP::Service::Action;

sub new {
    my ($class,$service) = @_;
    my $self = $class->SUPER::new();

    $self->data($service);
    return $self;
}

sub name {
    my $self = shift;
    return "Action";
}

# Examine the SCPD for the list of actions
# FIXME - use an xml parser!
sub children {
    my $self = shift;

    my $scpd = $self->parent()->getscpd();
    if ($scpd !~ m/<actionList>(.*)<\/actionList>/si) {
        # something is wrong with the scpd
        return undef;
    }
    my $actionlist = $1;

    my @children;
    while ($actionlist =~ m/<action>(.*?)<\/action>/sgi) {
        my $node = UPnP::Service::Action->new($1);
        $node->parent($self);
        push @children, $node;
    }

    return @children;
}

1;
