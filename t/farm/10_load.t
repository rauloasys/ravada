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

sub test_domain_farm {
    my ($vm_name, $domain, $farm) = @_;

    $domain->farm($farm);
    ok($domain->farm,"Expecting domain belongs to a farm");
    
    ok($domain->farm eq $farm,"Expecting farm for domain ='$farm' "
                                .", got ".$domain->farm);

    my $domain_f = $RVD_FRONT->search_domain($domain->name);

    ok($domain_f->farm,"Expecting domain belongs to a farm");
    
    ok($domain_f->farm && $domain_f->farm eq $farm
        ,"Expecting farm for domain ='$farm' "
         .", got ".($domain_f->farm or '<UNDEF>'));

}
###############################################################

for my $vm_name (qw(Void )) {

    my $class = "Ravada::Farm::$vm_name";

    use_ok($class);

    my $farm0 = {};
    bless $farm0,$class;

    #TODO test new farm with name, or id, not both
    my $farm = $farm0->new ( name => new_domain_name() );
    
    my $vm = $RVD_BACK->search_vm($vm_name);
    $farm->add_node($vm);

    my $domain = $RVD_BACK->create_domain( 
               vm => $vm
            ,name => new_domain_name()
        ,id_owner => $USER->id
    );
    
    test_domain_farm($vm_name, $domain, $farm);
    
    $domain->start($USER);
    test_domain_ip($vm_name, $farm, $domain);
    
    my $clone = $domain->clone(user => $USER, name => new_domain_name);
    $clone->start($USER);
    test_domain_ip($vm_name, $farm, $clone);

    ok($clone->farm,"Expecting clone belongs to a farm");
    ok($clone->farm && $clone->farm eq $domain->farm
        ,"Expecting clone belongs to the base farm");
}
done_testing();
