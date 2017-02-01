use warnings;
use strict;

use Data::Dumper;
use JSON::XS;
use YAML qw(LoadFile);
use Test::More;
use Test::SQL::Data;

use lib 't/lib';
use Test::Ravada;

my $test = Test::SQL::Data->new(config => 't/etc/sql.conf');

use_ok('Ravada');

my $FILE_CONFIG = 't/etc/ravada.conf';
my $FILE_CONFIG_REMOTE = "t/etc/remote_vm.conf";

my @ARG_RVD = ( config => $FILE_CONFIG,  connector => $test->connector);
init($test->connector, $FILE_CONFIG);

my $IP;

sub init_ip {
    return if !-e $FILE_CONFIG_REMOTE;

    open my $in ,'<', $FILE_CONFIG_REMOTE;
    $IP =<$in>;
    chomp $IP;
    close $in;
}

###########################################################3

init_ip();

SKIP: {
    if (!defined $IP) {
        my $msg = "skipped, missing the remote testing IP in the file $FILE_CONFIG_REMOTE";
        diag($msg);
        skip($msg,10);
    }
    my $vm = Ravada::VM::KVM->new(
        host => $IP
    );

    ok($vm);

    my $rvd_back = rvd_back();

    my $vm_name = 'remote_kvm';
    my $vm2;
    eval {
        $vm2 = $rvd_back->add_vm(
                  name => $vm_name
                , type => 'kvm'
                , host => $IP
        );
    };
    is($@,'');
    ok($vm2,"Expecting VM");

    ok(defined $vm2 && $vm2->name eq $vm_name);
    ok(defined $vm2 && $vm2->host eq $IP);
    ok(defined $vm2 && lc($vm2->type) eq 'kvm');

    eval { 
        $rvd_back->add_vm(
              name => $vm_name
            , type => 'kvm'
        );
    };
    like($@ ,qr/duplicate|unique/i);
}

done_testing();
