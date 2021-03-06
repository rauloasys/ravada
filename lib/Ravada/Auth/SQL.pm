package Ravada::Auth::SQL;

use warnings;
use strict;

=head1 NAME

Ravada::Auth::SQL - SQL authentication library for Ravada

=cut

use Carp qw(carp);

use Ravada;
use Ravada::Front;
use Digest::SHA qw(sha1_hex);
use Hash::Util qw(lock_hash);
use Moose;

use Data::Dumper;

with 'Ravada::Auth::User';


our $CON;

sub _init_connector {
    my $connector = shift;

    $CON = \$connector                 if defined $connector;
    return if $CON;

    $CON= \$Ravada::CONNECTOR          if !$CON || !$$CON;
    $CON= \$Ravada::Front::CONNECTOR   if !$CON || !$$CON;

    if (!$CON || !$$CON) {
        my $ravada = Ravada->new();
        $CON= \$Ravada::CONNECTOR;
    }

    die "Undefined connector"   if !$CON || !$$CON;
}


=head2 BUILD

Internal OO build method

=cut

sub BUILD {
    _init_connector();

    my $self = shift;

    $self->_load_data();

    return $self if !$self->password();

    die "ERROR: Login failed ".$self->name
        if !$self->login();#$self->name, $self->password);
    return $self;
}

=head2 search_by_id

Searches a user by its id

    my $user = Ravada::Auth::SQL->search_by_id( $id );

=cut

sub search_by_id {
    my $self = shift;
    my $id = shift;
    my $data = _load_data_by_id($id);
    return Ravada::Auth::SQL->new(name => $data->{name});
}

=head2 add_user

Adds a new user in the SQL database. Returns nothing.

    Ravada::Auth::SQL::add_user(
                 name => $user
           , password => $pass
           , is_admin => 0
       , is_temporary => 0
    );

=cut

sub add_user {
    my %args = @_;

    _init_connector();

    my $name= $args{name};
    my $password = $args{password};
    my $is_admin = ($args{is_admin} or 0);
    my $is_temporary= ($args{is_temporary} or 0);

    delete @args{'name','password','is_admin','is_temporary'};

    confess "WARNING: Unknown arguments ".Dumper(\%args)
        if keys %args;

    my $sth = $$CON->dbh->prepare(
            "INSERT INTO users (name,password,is_admin,is_temporary, is_external)"
            ." VALUES(?,?,?,?,?)");

    if ($password) {
        $password = sha1_hex($password);
    } else {
        $password = '*LK* no pss';
    }
    $sth->execute($name,$password,$is_admin,$is_temporary
        , ($args{is_external} or 0));
    $sth->finish;
}

sub _load_data {
    my $self = shift;
    _init_connector();

    die "No login name nor id " if !$self->name && !$self->id;

    my $sth = $$CON->dbh->prepare(
       "SELECT * FROM users WHERE name=? ");
    $sth->execute($self->name);
    my ($found) = $sth->fetchrow_hashref;
    $sth->finish;

    return if !$found->{name};

    delete $found->{password};
    lock_hash %$found;
    $self->{_data} = $found if ref $self && $found;
}

sub _load_data_by_id {
    my $id = shift;
    _init_connector();

    my $sth = $$CON->dbh->prepare(
       "SELECT * FROM users WHERE id=? ");
    $sth->execute($id);
    my ($found) = $sth->fetchrow_hashref;
    $sth->finish;

    delete $found->{password};
    lock_hash %$found;

    return $found;
}

=head2 login

Logins the user

     my $ok = $user->login($password);
     my $ok = Ravada::LDAP::SQL::login($name, $password);

returns true if it succeeds

=cut


sub login {
    my $self = shift;

    _init_connector();

    my ($name, $password);

    if (ref $self) {
        $name = $self->name;
        $password = $self->password;
        $self->{_data} = {};
    } else { # old login API
        $name = $self;
        $password = shift;
    }


    my $sth = $$CON->dbh->prepare(
       "SELECT * FROM users WHERE name=? AND password=?");
    $sth->execute($name , sha1_hex($password));
    my ($found) = $sth->fetchrow_hashref;
    $sth->finish;

    if ($found) {
        lock_hash %$found;
        $self->{_data} = $found if ref $self && $found;
    }

    return 1 if $found;

    return;
}

=head2 make_admin

Makes the user admin. Returns nothing.

     Ravada::Auth::SQL::make_admin($id);

=cut

sub make_admin {
    my $id = shift;
    my $sth = $$CON->dbh->prepare(
            "UPDATE users SET is_admin=1 WHERE id=?");

    $sth->execute($id);
    $sth->finish;

}

=head2 remove_admin

Remove user admin privileges. Returns nothing.

     Ravada::Auth::SQL::remove_admin($id);

=cut

sub remove_admin {
    my $id = shift;
    my $sth = $$CON->dbh->prepare(
            "UPDATE users SET is_admin=NULL WHERE id=?");

    $sth->execute($id);
    $sth->finish;

}

=head2 is_admin

Returns true if the user is admin.

    my $is = $user->is_admin;

=cut


sub is_admin {
    my $self = shift;
    return $self->{_data}->{is_admin};
}

=head2 is_external

Returns true if the user authentication is not from SQL

    my $is = $user->is_external;

=cut


sub is_external {
    my $self = shift;
    return $self->{_data}->{is_external};
}


=head2 is_temporary

Returns true if the user is admin.

    my $is = $user->is_temporary;

=cut


sub is_temporary{
    my $self = shift;
    return $self->{_data}->{is_temporary};
}


=head2 id

Returns the user id

    my $id = $user->id;

=cut

sub id {
    my $self = shift;
    my $id;
    eval { $id = $self->{_data}->{id} };
    confess $@ if $@;

    return $id;
}

=head2 change_password

Changes the password of an User

    $user->change_password();

Arguments: password

=cut

sub change_password {
    my $self = shift;
    my $password = shift or die "ERROR: password required\n";

    die "Password too small" if length($password)<6;

    my $sth= $$CON->dbh->prepare("UPDATE users set password=?"
        ." WHERE name=?");
    $sth->execute(sha1_hex($password), $self->name);
}

=head2 language

  Updates or selects the language selected for an User

    $user->language();

  Arguments: lang

=cut

  sub language {
    my $self = shift;
    my $tongue = shift;
    if (defined $tongue) {
      my $sth= $$CON->dbh->prepare("UPDATE users set language=?"
          ." WHERE name=?");
      $sth->execute($tongue, $self->name);
    }
    else {
      my $sth = $$CON->dbh->prepare(
         "SELECT language FROM users WHERE name=? ");
      $sth->execute($self->name);
      return $sth->fetchrow();
    }
  }

1;
