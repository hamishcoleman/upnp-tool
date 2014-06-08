package CommandLine;
use warnings;
use strict;

use HC::Net::UPnP::ControlPoint;

our $VERBOSE = 0;
my $METHODS = {
    show => \&show,
};


sub HANDLE {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->{ControlPoint} = HC::Net::UPnP::ControlPoint->new();

    my $command = lc shift;
    my @args = @_;

    if (!defined($METHODS->{$command})) {
        return undef;
    }

    return $METHODS->{$command}($self,$command,@args);
}

sub show {
    my $self = shift;
    my $command = shift;

    my @devices = $self->{ControlPoint}->getdevices();

    my $db = {};
    for my $device (@devices) {
        push @{$db->{$device->getfriendlyname()}},$device;
    }

    my $maxnamelen =0;
    for my $name (keys %{$db}) {
        if (length($name) > $maxnamelen) {
            $maxnamelen = length($name);
        }
    }

    for my $name (sort keys %{$db}) {
        printf("%-*s ",$maxnamelen,$name);
        my $prefix = '';
        if (scalar(@{$db->{$name}}) > 1) {
            printf("\n");
            $prefix = '  ';
        }
        my @sorted = sort { $a->getdevicetype() cmp $b->getdevicetype() }
            @{$db->{$name}};
        for my $device (@sorted) {
            printf("%s%s\n",$prefix,$device->getdevicetype());
            if ($VERBOSE) {
                printf("%s  %s\n",$prefix,$device->getlocation());
            }
        }
    }
}


1;

