use warnings;
use strict;

use Carp qw(confess);
use Data::Dumper;
use Test::More;
use Test::SQL::Data;

use lib 't/lib';
use Test::Ravada;

my $test = Test::SQL::Data->new(config => 't/etc/sql.conf');

use_ok('Ravada');

my $FILE_CONFIG = 't/etc/ravada.conf';

init($test->connector, $FILE_CONFIG);
my $USER = create_user('foo','bar');

my $TIME_BOOT = 30;

#################################################################

sub test_create_domain {
    my $vm_name = shift;

    my $vm = rvd_back->search_vm($vm_name);
    ok($vm,"I can't find VM $vm_name") or return;

    my $name = new_domain_name();

    my $domain;

    $domain = $vm->search_domain($name);
    if ($domain ) {
        rvd_back->import_domain(name => $name, vm => $vm_name, user => $USER->name);
        return $domain;
    }

    eval { $domain = $vm->create_domain(name => $name
                    , id_owner => $USER->id
                    , id_iso => 20
            );
    };
    is($@,'') or return;
    ok($domain);
    ok($domain->name
        && $domain->name eq $name,"Expecting domain name '$name' , got "
        .($domain->name or '<UNDEF>')
        ." for VM $vm_name"
    );
    $domain->start($USER);
    sleep 3;
    $domain->domain->send_key(
        Sys::Virt::Domain::KEYCODE_SET_RFB
        ,1000, [28]
    );

    return $domain;
}

sub test_format_disk {
    my ($vm_name, $domain) = @_;

    my ($dev, $mount) = ('/dev/sda', '/diska1');

    sleep $TIME_BOOT;
    $domain->domain->send_key(
        Sys::Virt::Domain::KEYCODE_SET_RFB
        ,1000,[29,56,60]);
    sleep 3;
    send_line($domain,'root','woofwoof');
    sleep 3;
    send_line($domain,"fdisk $dev");
    sleep 1;
    send_line($domain,'n','p','1','','','w');
    sleep 1;
    send_line($domain,"mkfs.ext3 ${dev}1");
    sleep 2;
    send_line($domain,"mkdir $mount");
    send_line($domain,"mount ${dev}1 $mount");
}

sub send_use_disk {
    my ($vm_name, $domain) = @_;
    send_line($domain,"for i in `ls /usr/bin/`; do echo \$i "
                        ."; cp /usr/bin/\$i /diska1/ "
                        .'; sleep 0.1'
                        ."; rm /diska1/\$i"
                     ."; done");
}

sub test_compare_cpu_load {
    my ($vm_name) = shift;
    for ( 1 .. 60 ) {
        my $msg = '';
        for (@_) {
            $msg .= $_->cpu_load." ";
        }
        diag($msg);
        sleep 1;
    }
}

sub test_compare_disk_load {
    my ($vm_name, $domain1, $domain2) = @_;
    my $rvd = rvd_back();
    for ( 1 .. 60 ) {
        my $msg = '';
        $rvd->pause_inactive_domains(10);
#        for ($domain1, $domain2) {
#            my $msg = $_->name." ".$_->disk_load." => ".$_->recent_disk_load(10)." ";
#            diag("$msg\n");
#        }
        last if $domain2->is_paused;
        sleep 1;
    }
    ok($domain1->is_active,"Domain 1 ".$domain1->name." should be active");
    ok(!$domain1->is_paused,"Domain 1 ".$domain1->name
        ." should not be paused");
    ok($domain2->is_active,"Domain 2 ".$domain2->name." should be active");
    ok($domain2->is_paused,"Domain 2 ".$domain2->name
        ." should be paused");

}


#################################################################

#remove_old_domains();
#remove_old_disks();

for my $vm_name ('KVM') {

    diag("Testing $vm_name VM");
    my $CLASS= "Ravada::VM::$vm_name";

    use_ok($CLASS);

    my $vm;

    eval { $vm = rvd_back->search_vm($vm_name) };

    SKIP: {
        my $msg = "SKIPPED test: No $vm_name VM found ";
        diag($msg)      if !$vm;
        skip $msg,10    if !$vm;

        my $domain1 = test_create_domain($vm_name) or next;
        my $domain2 = test_create_domain($vm_name) or next;

#        test_compare_cpu_load($vm_name, $domain1,$domain2);
        test_format_disk($vm_name, $domain1);
#        test_format_disk($vm_name, $domain2);
        send_use_disk($vm_name, $domain1);
#
        test_compare_disk_load($vm_name, $domain1,$domain2);
    }
}
#remove_old_domains();
#remove_old_disks();

done_testing();
