#!/usr/bin/perl -w

use strict;

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More qw(no_plan);
# use Test::File::Contents;
use File::Compare;
use File::Copy "cp";
use FindBin qw($Bin);
use Getopt::Long;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use lib "$Bin/../../../../../..";

BEGIN {
    use_ok('Test::Conf::StarCluster'); 
}
require_ok('Test::Conf::StarCluster');

#### INTERNAL MODULES
use Test::Conf::StarCluster;

#### SET LOGFILE
my $logfile     =   "$Bin/outputs/test.log";
my $log         =   2;
my $printlog    =   5;

my $help;
GetOptions (
    'logfile=s'     =>  \$logfile,
    'log=s'         =>  \$log,
    'printlog=s'    =>  \$printlog,
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### FILES
my $originalfile    =   "$Bin/inputs/syoung-microcluster.config";
my $inputfile       =   "$Bin/outputs/syoung-microcluster.config";
my $emptyfile       =   "$Bin/inputs/syoung-microcluster-empty.config";
my $addedfile       =   "$Bin/inputs/syoung-microcluster-added.config";
my $removedfile     =   "$Bin/inputs/syoung-microcluster-removed.config";

### TEST CONF
my $object = Test::Conf::StarCluster->new(
    logfile     =>  $logfile,
	backup      =>	0,
    log         =>  $log,
    printlog    =>  $printlog
);

$object->testGetKey($originalfile, $inputfile);
$object->testSetKey($originalfile, $inputfile, $addedfile);
$object->testRemoveKey($originalfile, $inputfile, $removedfile);

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

