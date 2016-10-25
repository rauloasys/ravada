use warnings;
use strict;

use Test::More;
use Test::SQL::Data;

use lib 't/lib';
use Test::Ravada;

my $test = Test::SQL::Data->new( config => 't/etc/sql.conf');

my $RVD_BACK = rvd_back( $test->connector , 't/etc/ravada.conf');
my $USER = create_user('foo', 'bar');

use_ok('Ravada::Farm');

sub test_domain_ip {
    my ($vm_name, $farm, $domain) = @_;
    my $display = $domain->display();
    
    my ($ip) = $display =~ m{\d+\.\d+\.\d+\.\d+};
    
    my $found = 0;
    for my $vm ( $farm->list_vms) {
        $found++ if $vm->ip == $ip;
    }
    
    ok($found == 1, "Domain ip ($ip) expected in 1 VM, found in $found VMs");
    
}
    
###############################################################

for my $vm_name (qw(Void KVM)) {

    my $class = "Ravada::Farm::$vm_name";

    use_ok($class);

    my $farm0 = {};
    bless $farm0,$class;

    my $farm = $farm0->new ( name => new_domain_name() );
    
    my $vm = $RVD_BACK->search_vm($vm_name);
    $farm->add_node($vm);

    my $domain = $RVD_BACK->create_domain( 
               vm => $vm
            ,name => new_domain_name()
        ,id_owner => $USER->id
    );
    
    $domain->add_to_farm($farm);
    
    ok($domain->farm eq $farm,"Expecting farm for domain ='$farm' "
                                .", got ".$domain->farm);
    
    $domain->start();
    test_domain_ip($vm_name, $farm, $domain);
    
    my $clone = $domain->clone($USER);
    $clone->start();
    test_domain_ip($vm_name, $farm, $clone);
    
}
done_testing();
