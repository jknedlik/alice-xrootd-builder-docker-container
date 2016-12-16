#!/usr/bin/perl

use strict;
use warnings;
use Config::Simple;
my $Conf=new Config::Simple('./apmon.conf');
my %cfg=$Conf->vars();

print  $cfg{'xrootd.SE_Name'} .'_'. $cfg{'xrootd.InstanceType'} . "_xrootd_Services\n";
my $x=`echo ${cfg{'xrootd.SE_Name'}}`;
print $x;
