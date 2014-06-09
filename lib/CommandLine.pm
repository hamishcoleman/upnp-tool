package CommandLine;
use warnings;
use strict;

use HC::Net::UPnP::ControlPoint;
use HC::Net::UPnP::Service;

use URI;
use Data::Dumper;

our $VERBOSE = 0;


#
sub show_devices {
    my @devices = @_;

    # group devices by their name
    my $db = {};
    for my $device (@devices) {
        push @{$db->{$device->getfriendlyname()}},$device;
    }

    # find the length of the longest description
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

sub show_services {
    my @services = @_;

    # arrange by service type
    my $db;
    for my $service (@services) {
        push @{$db->{$service->getservicetype()}},$service;
    }

    #
    for my $type (sort keys %{$db}) {
        printf("  %s\n",$type);

        my @sorted = sort { $a->getserviceid() cmp $b->getserviceid() }
            @{$db->{$type}};
        for my $service (@sorted) {
            printf("    %s\n",$service->getserviceid());
            if ($VERBOSE) {
                printf("      %s\n",$service->getscpdurl_real());
            }
        }
    }
}

sub show_actions {
    my @actions = @_;

    my @sorted = sort { $a->getname() cmp $b->getname() } @actions;
    for my $action (@sorted) {
        printf("      %s\n",$action->getname());
    }
}

sub show_arguments {
    my @arguments = @_;

    my @sorted = sort { $a cmp $b } @arguments;
    for my $argument (@sorted) {
        printf("        %s\n",$argument);
    }
}

sub HANDLE {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->{ControlPoint} = HC::Net::UPnP::ControlPoint->new();

    my $filter_name = shift;

    my @devices;
    if (($filter_name||'') =~ m/^http/) {
        @devices = $self->{ControlPoint}->getdevicebyurl($filter_name);
    } else {
        @devices = $self->{ControlPoint}->getfiltereddevices($filter_name);
    }

    my $filter_type = shift;
    if (defined($filter_type)) {
        @devices = grep {$_->getdevicetype() =~ m/$filter_type/} @devices;
    }

    show_devices(@devices);

    # if we have more than one device, show no more information
    if (scalar(@devices) != 1) {
        return 1;
    }

    my $filter_servicetype = shift;
    my @services= HC::Net::UPnP::Service->import($devices[0]->getservicelist());

    if (defined($filter_servicetype)) {
        @services = grep {
            $_->getservicetype() =~ m/$filter_servicetype/
        } @services;
    }

    my $filter_serviceid = shift;
    if (defined($filter_serviceid)) {
        @services = grep {
            $_->getserviceid() =~ m/$filter_serviceid/
        } @services;
    }

    show_services(@services);

    # if we have more than one service, show no more information
    if (scalar(@services) != 1) {
        return 1;
    }

    my @actions = $services[0]->actionlist();

    # TODO - apparently there are also state variables
    my $filter_action = shift;
    if (defined($filter_action)) {
        @actions = grep {
            $_->getname() =~ m/$filter_action/
        } @actions;
    }

    show_actions(@actions);

    # if we have more than one, show no more information
    if (scalar(@actions) != 1) {
        return 1;
    }

    my @arguments = $actions[0]->argumentlist_in();

    show_arguments(@arguments);

    my $command = shift;
    if (!defined($command)) {
        return 1;
    }

    # TODO - load kwargs from commandline

    my $action_res = $services[0]->postaction($actions[0]->getname ());

    if ($action_res->getstatuscode() != 200) {
        printf("Error: Status: %i\n",$action_res->getstatuscode());
        return 0;
    }

    print("\nResults:\n");
    print(Dumper($action_res->getargumentlist()));
}


1;

