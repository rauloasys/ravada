package Ravada::Farm::Node;

use warnings;
use strict;

use Carp qw(confess croak cluck);
use Data::Dumper;

use Moose;

####################################################

has 'type' => (
    isa => 'Str'
    ,is => 'ro'
);

has 'name' => (
    isa => 'Str'
    ,is => 'ro'
);

has 'vm' => (
    isa => 'Ravada::VM'
    ,is => 'ro'
    ,required => 1
);

has 'public_ip' => (
    isa => 'Str',
    ,is => 'rw'
);

has 'private_ip' => (
    isa => 'Str',
    ,is => 'rw'
);

has 'enabled' => (
    isa => 'Int'
    ,is => 'rw'
    ,default => 1
);

has 'snmp_community' => (
    isa => 'Str'
    ,is => 'rw'
);

#####################################################

sub is_alive {
# ping
}

sub mem {
#TODO add memory support for Ravada::VM
}

sub free_mem {
#TODO add memory support for Ravada::VM
}

sub load {
#TODO SNMP
}

1;
