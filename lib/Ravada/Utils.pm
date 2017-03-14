package Ravada::Utils;

=head2 now

Returns the current datetime

=cut

sub now {
     my @now = localtime(time);
    $now[5]+=1900;
    $now[4]++;
    for ( 0 .. 4 ) {
        $now[$_] = "0".$now[$_] if length($now[$_])<2;
    }

    return "$now[5]-$now[4]-$now[3] $now[2]:$now[1]:$now[0].0";
}

=head2 df_free

Returns the current disk available in pool

=cut
sub df_free{ 
    use Filesys::DiskSpace;
    #sudo apt-get install libfilesys-diskspace-perl
    # file system /home or /dev/sda5
    my $dir = "/var/lib/libvirt/images";
 
    # get data for dir fs
    my ($fs_type, $fs_desc, $used, $avail, $fused, $favail) = df $dir;
 
    # calculate free space in %
    my $df_free = (($avail) / ($avail+$used)) * 100.0;
  
    #my $out = sprintf("Disk space on $dir == %0.2f\n",$df_free);
    return "$df_free";
}

=head2 spool_free

Returns the available space for creation of new volumes. This may be less than the difference between capacity & allocation if there are sizing/metadata constraints for volume

=cut
sub spool_free{
    use Ravada;
    use Ravada::VM::KVM;
    use Sys::Virt::StoragePool;
    
    my $vm = $ravada->open_vm('KVM'); 
    my $sp = $vm->storage_pool(); 
    my $info = $sp->get_info(available); 
    return $info;
}
1;
