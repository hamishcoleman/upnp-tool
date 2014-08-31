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
    my @children;

    my $scpd = $self->parent()->getscpd();
    if (!defined($scpd)) {
        # something went wrong with fetching the scpd
        return @children;
    }
    if ($scpd !~ m/<actionList>(.*)<\/actionList>/si) {
        # something is wrong with the scpd data
        return @children;
    }
    my $actionlist = $1;

    while ($actionlist =~ m/<action>(.*?)<\/action>/sgi) {
        my $node = UPnP::Service::Action->new($1);
        $node->parent($self);
        push @children, $node;
    }

    return @children;
}

1;
