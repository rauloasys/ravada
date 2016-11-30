use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::SQL::Data;

use lib 't/lib';
use Test::Ravada;

my $test = Test::SQL::Data->new( config => 't/etc/sql.conf');

my $RVD_BACK = rvd_back( $test->connector , 't/etc/ravada.conf');
my $RVD_FRONT = rvd_front( $test->connector , 't/etc/ravada.conf');
my $USER = create_user('foo', 'bar');

use_ok('Ravada::Farm');
use_ok('Ravada::Farm::Node');

my $VM_IP;
my $VM_TYPE;

sub load_config {

    my $file_config = "$0.conf";
    $file_config =~ s{^t(/\w+)/}{t/etc${1}_};
    if (! -e $file_config ){
        diag("SKIPPED: No $file_config");
        return;
    }
    my $config = YAML::LoadFile($file_config);

    $VM_IP = $config->{ip};
    $VM_TYPE = $config->{type};
    if (!$VM_IP || !$VM_TYPE) {
        $config = { ip => '0.0.0.0', type => 'KVM' };
        warn "ERROR: File $file_config must be like:\n"
            .YAML::Dump($config);
        return;
    }
    if ($VM_IP eq '0.0.0.0') {
        warn "ERROR: IP from $file_config must be from a real server\n";
        return;
    }
}

sub test_domain_ip {
    my ($vm_name, $farm, $domain) = @_;
    my $display = $domain->display($USER);
    
    my ($ip) = $display =~ m{(\d+\.\d+\.\d+\.\d+)};
    
    my $found = 0;
    for my $node ( @{$farm->nodes}) {
        $found++ if $node->public_ip eq $ip;
    }
    
    ok($found == 1, "Domain ip ($ip) expected in 1 VM, found in $found VMs");
    
}

###############################################################

load_config();

SKIP: {
skip("No remote node",3)    if !$VM_IP;

for my $vm_name (qw(Void )) {

    my $farm_class = "Ravada::Farm::$vm_name";
    use_ok($farm_class);

    my $farm0 = {};
    bless $farm0,$farm_class;
    my $farm = $farm0->new ( name => 'test_farm');

    ok($farm->id,"Expecting farm id") or exit;
    
    my $vm_class = "Ravada::VM::$vm_name";
    my $vm0 = {};
    bless $vm0, $vm_class;

    my $vm = $vm0->new(hostname => $VM_IP);
    $farm->add_node($vm);

    my $domain = $RVD_BACK->create_domain( 
               vm => $vm
            ,name => new_domain_name()
        ,id_owner => $USER->id
    );
    
    $domain->farm($farm);
    
    $domain->start($USER);
    test_domain_ip($vm_name, $farm, $domain);
    
    my $clone = $domain->clone(user => $USER, name => new_domain_name);
    $clone->start($USER);
    test_domain_ip($vm_name, $farm, $clone);

    ok($clone->farm,"Expecting clone belongs to a farm");
    is($clone->farm && $clone->farm->id, $domain->farm->id);
}
}
done_testing();
