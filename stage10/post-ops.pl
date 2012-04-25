#!/usr/bin/perl

print "Running post-ops\n";

$ec2timeout = 10;

$done=$count=0;
while(!$done) {
    chomp($ipa=`runat $ec2timeout euca-describe-volumes | grep available | tr -s ' ' | cut -f 2`);
    if (($ipa =~ /vol/) || $count > 600) {
	$done++;
    }
    $count++;
}
if (!$ipa) {
    print "ERROR: could not get volume\n";
    system("runat $ec2timeout euca-describe-volumes");
    exit(1);
}

exit $rc;
