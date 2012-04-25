#!/usr/bin/perl

require "ec2ops.pl";

my $account = shift @ARGV || "eucalyptus";
my $user = shift @ARGV || "admin";

# need to add randomness, for now, until account/user group/keypair
# conflicts are resolved

$rando = int(rand(10)) . int(rand(10)) . int(rand(10));
if ($account ne "eucalyptus") {
    $account .= "$rando";
}
if ($user ne "admin") {
    $user .= "$rando";
}
$newgroup = "ebsgroup$rando";
$newkeyp = "ebskey$rando";

parse_input();
print "SUCCESS: parsed input\n";

setlibsleep(2);
print "SUCCESS: set sleep time for each lib call\n";

setcleanup("no");

setkeypath("../artifacts");

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

discover_emis();
print "SUCCESS: discovered loaded image: current=$current_artifacts{instancestoreemi}, all=$static_artifacts{instancestoreemis}\n";

discover_zones();
print "SUCCESS: discovered available zone: current=$current_artifacts{availabilityzone}, all=$static_artifacts{availabilityzones}\n";

if ( ($account ne "eucalyptus") && ($user ne "admin") ) {
# create new account/user and get credentials
    create_account_and_user($account, $user);
    print "SUCCESS: account/user $current_artifacts{account}/$current_artifacts{user}\n";
    
    grant_allpolicy($account, $user);
    print "SUCCESS: granted $account/$user all policy permissions\n";
    
    get_credentials($account, $user);
    print "SUCCESS: downloaded and unpacked credentials\n";
    
    source_credentials($account, $user);
    print "SUCCESS: will now act as account/user $account/$user\n";
}
# moving along

add_keypair("$newkeyp");
print "SUCCESS: added new keypair: $current_artifacts{keypair}, $current_artifacts{keypairfile}\n";

add_group("$newgroup");
print "SUCCESS: added group: $current_artifacts{group}\n";

authorize_ssh();
print "SUCCESS: authorized ssh access to VM\n";

run_instances(1);
print "SUCCESS: ran instance: $current_artifacts{instance}\n";

wait_for_instance();
print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";

wait_for_instance_ip();
print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";

wait_for_instance_ip_private();
print "SUCCESS: instance got private IP: $current_artifacts{instanceprivateip}\n";

ping_instance_from_cc();
print "SUCCESS: instance private IP pingable from CC: instanceip=$current_artifacts{instanceprivateip} ccip=$current_artifacts{instancecc}\n";
sleep(30);

create_volume(1);
print "SUCCESS: created volume: vol=$current_artifacts{volume}\n";

wait_for_volume();
print "SUCCESS: volume became available: vol=$current_artifacts{volume}, volstate=$current_artifacts{volumestate}\n";

attach_volume();
print "SUCCESS: attached volume: volstate=$current_artifacts{volumestate}\n";

wait_for_volume_attach();
print "SUCCESS: volume became attached: volstate=$current_artifacts{volumestate}\n";

find_instance_volume();
$idev = $current_artifacts{instancedevice};
print "SUCCESS: discovered instance local EBS dev name: $idev\n";

doexit(0, "EXITING SUCCESS\n");
