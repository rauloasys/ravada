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

my @ARG_RVD = ( config => $FILE_CONFIG,  connector => $test->connector);
init($test->connector, $FILE_CONFIG);

my $IP = init_ip();
my $USER = create_user('foo','bar');

##########################################################################

sub test_create_domain {
    my $vm = shift;

    my $name = new_domain_name();

    my $domain;
    eval { $domain = $vm->create_domain(
            name => $name
            ,id_owner => $USER->id
            ,id_iso => 1
        );
    };
    ok(!$@,"Expecting no error creating domain in remote VM at $IP, got '"
            .($@ or '<UNDEF>')."'");
    ok($domain) or return;

    return $domain;
}

###########################################################3

init_ip();

remove_old_domains();
remove_old_disks();

SKIP: {
    if (!defined $IP) {
        my $msg = "skipped, missing the remote testing IP in the file "
            .$Test::Ravada::FILE_CONFIG_REMOTE;
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
                , type => 'KVM'
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

    my $vm3 = $rvd_back->search_vm($vm_name);
    ok($vm3,"Expecting a VM searching for '$vm_name'");

    my $domain = test_create_domain($vm3);
}

remove_old_domains();
remove_old_disks();

done_testing();
