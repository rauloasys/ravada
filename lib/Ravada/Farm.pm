package Ravada::Farm;

use warnings;
use strict;

use Carp qw(confess croak cluck);
use Data::Dumper;

use Moose;

our $CONNECTOR;

_init_connector();

has 'type' => (
    isa => 'Str'
    ,is => 'ro'
);

has 'name' => (
    isa => 'Str'
    ,is => 'ro'
);

###############################################################

sub _init_connector {
    $CONNECTOR = \$Ravada::CONNECTOR;
    $CONNECTOR = \$Ravada::Front::CONNECTOR if !defined $$CONNECTOR;
}

###############################################################

1;
