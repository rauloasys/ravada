package Ravada::Farm;

use warnings;
use strict;

use Carp qw(confess croak cluck);
use Data::Dumper;

use Moose::Role;

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

has 'nodes' => (
    isa => 'ArrayRef'
    ,is => 'rw'
    ,default => sub { [] }
);

###############################################################

sub _init_connector {
    $CONNECTOR = \$Ravada::CONNECTOR;
    $CONNECTOR = \$Ravada::Front::CONNECTOR if !defined $$CONNECTOR;
}

###############################################################

sub add_node {
    my $self = shift;
    my $node = shift or confess "Missing node";

    push  @{$self->nodes},($node);

}

1;
