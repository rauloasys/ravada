package Ravada::Farm;

use warnings;
use strict;

use Carp qw(confess croak cluck);
use Data::Dumper;

use Moose::Role;

use Ravada::Farm::Node;

our $CONNECTOR;

#################################################################


requires 'sync_base';
requires 'choose_node';

#################################################################

before 'sync_base' => \&_disable_all_nodes;

###############################################################33


has 'type' => (
    isa => 'Str'
    ,is => 'rw'
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

has 'id' => (
    isa => 'Int'
    ,is => 'rw'
);

###############################################################
_init_connector();

sub _init_connector {
    $CONNECTOR = \$Ravada::CONNECTOR;
    $CONNECTOR = \$Ravada::Front::CONNECTOR if !defined $$CONNECTOR;
}

###############################################################

sub add_node {
    my $self = shift;
    my $vm = shift or confess "Missing vm";

    push  @{$self->nodes},(Ravada::Farm::Node->new(vm => $vm));

}

sub BUILD {
    my $self = shift;
    my ($args) = @_;

    my $id = $args->{id};
    my $name = $args->{name};

    my $type = ref($self);
    $type =~ s/.*:://;
    $self->type($type);

    confess "ERROR: supply either id or name, not both ".Dumper(\@_)
        if defined $id && defined $name;

    return $self->_open($id)     if defined $id;
    return $self->_create(%$args) if $name;
    
    confess "ERROR: supply at least id or name ".Dumper(\@_);
}

sub _open {
    #TODO: load from DB
}

sub _create {
    my $self = shift;

    my $sth = $$CONNECTOR->dbh->prepare(
        "INSERT INTO farms "
        ."( name, type ) "
        ." VALUES(?,?)"
    );
    $sth->execute($self->name, $self->type);
    $sth->finish;

    $sth = $$CONNECTOR->dbh->prepare(
        "SELECT id FROM farms"
        ." WHERE name=?"
    );
    $sth->execute($self->name);
    $self->id($sth->fetchrow);
    $sth->finish;
}

sub _disable_all_nodes {
    
}

1;
