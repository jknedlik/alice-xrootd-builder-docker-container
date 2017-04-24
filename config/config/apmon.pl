#!/usr/bin/perl

use strict;
use warnings;
use Config::Simple;
use Data::Dumper;


if (!(-f $ARGV[0]))
{
  print "Could not find the specified config file '" . $ARGV[0] . "'\n";
  exit 1;
}
my $Conf=new Config::Simple($ARGV[0]);
print Dumper($Conf);
my %cfg=$Conf->vars();
if("false" eq $cfg{'apmon.enable'}){
  while(1){sleep(120);}
}
else{
  use ApMon;
  my $apm = new ApMon(0);

  $apm->setLogLevel($cfg{'apmon.LogLevel'});
  $apm->setDestinations($cfg{'apmon.MonitorClusterNode'});
  $apm->setMonitorClusterNode($cfg{'xrootd.SE_Name'} . "_SysInfo",  $cfg{'xrootd.Fqdn'});
  my $command="systemctl -p MainPID show cmsd@"."$cfg{'xrootd.InstanceName'} | awk -F'=' '{print \$2}'";
  my $cmsdPID =`$command`;
  $command="systemctl -p MainPID show xrootd@"."$cfg{'xrootd.InstanceName'} | awk -F'=' '{print \$2}'";
  my $xrootdPID=`$command`;
  $apm->addJobToMonitor($cmsdPID, '', $cfg{'xrootd.SE_Name'} ."_". $cfg{'xrootd.InstanceType'} . '_cmsd_Services');
  $apm->addJobToMonitor($xrootdPID, '',  $cfg{'xrootd.SE_Name'} ."_". $cfg{'xrootd.InstanceType'} . '_xrootd_Services');

  my $pid = fork();

  if($pid == 0)
  {
    while(1)
  	{
      $apm->sendBgMonitoring();
  		my $xrdver=`xrd 127.0.0.1:${cfg{'xrootd.Port'}} query 1 /dummy | awk '{print \$3}' | cut -d'=' -f 2 `;
  		$xrdver =~ tr/"//d;
      print $xrdver;
      $apm->sendParameters( $cfg{'xrootd.SE_Name'} ."_". $cfg{'xrootd.InstanceType'} .'_xrootd_Services', $cfg{'xrootd.Fqdn'}, 'xrootd_version', $xrdver);
      {
        use integer;
        my $totsp = `xrdfs ${cfg{'xrootd.ManagerHost'}}:${cfg{'xrootd.Port'}} spaceinfo / | grep Total | cut -d':' -f 2 | tr -d ' ' `/(1024*1024);
  		  $apm->sendParameters($cfg{'xrootd.SE_Name'} ."_". $cfg{'xrootd.InstanceType'} .'_xrootd_Services',  $cfg{'xrootd.Fqdn'}, 'space_total', $totsp);
  		  my $freesp = `xrdfs ${cfg{'xrootd.ManagerHost'}}:${cfg{'xrootd.Port'}} spaceinfo / | grep Free | cut -d':' -f 2 | tr -d ' ' `/(1024*1024);
  		  $apm->sendParameters($cfg{'xrootd.SE_Name'} ."_". $cfg{'xrootd.InstanceType'} .'_xrootd_Services', $cfg{'xrootd.Fqdn'}, 'space_free', $freesp);
  		  my $lrgst = `xrdfs ${cfg{'xrootd.ManagerHost'}}:${cfg{'xrootd.Port'}} spaceinfo / | grep Largest | cut -d':' -f 2 | tr -d ' ' `/(1024*1024);
  		  $apm->sendParameters($cfg{'xrootd.SE_Name'} ."_". $cfg{'xrootd.InstanceType'} .'_xrootd_Services', $cfg{'xrootd.Fqdn'}, 'space_largestfreechunk', $lrgst);
      }
      sleep(120);
  	}
  }
  else
  {
  	my $Line;
  	my $Var;
  	my $Val;
  	my %Statsdata;
  	open my $Stdout, "mpxstats -f flat -p 1234 |";
  	while (<$Stdout>)
  	{
  		undef %Statsdata;
  		$Line = "$_";
  		($Var,$Val) = split(' ',$Line);
  		if(defined($Var))
  		{
  			$Statsdata{$Var} = $Val;
  		}
  		$apm->sendParameters($cfg{'xrootd.SE_Name'} .'_xrootd_ApMon_Info', $cfg{'xrootd.Fqdn'}, %Statsdata);
  	}
  }
}
