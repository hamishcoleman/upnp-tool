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

sub children {
    my $self = shift;

    my @actions = $self->_actionlist();
    my @children;
    for my $action (@actions) {
        my $node = UPnP::Service::Action->new($action);
        $node->parent($self);
        push @children, $node;
    }

    return @children;
}

# Examine the SCPD for the action list
# FIXME - use an xml parser!
sub _actionlist {
    my ($self) = shift;
    my $service = $self->data();

    my $scpd = $self->parent()->getscpd();
    if ($scpd !~ m/<actionList>(.*)<\/actionList>/si) {
        return undef;
    }
    my $actionlist = $1;

    my @actionlist = qw();
    while ($actionlist =~ m/<action>(.*?)<\/action>/sgi) {
        use HC::Net::UPnP::Service::Action;
        my $action = HC::Net::UPnP::Service::Action->new();
        $action->setdescription($1);
        $action->setservice($service);
        push @actionlist,$action;
    }
    return @actionlist;
}


1;
