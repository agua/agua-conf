#!/usr/bin/perl -w

use strict;

#### EXTERNAL MODULES
use Test::More  tests => 34;
use FindBin qw($Bin);
use Getopt::Long;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use lib "$Bin/../../../../../..";

BEGIN {
    use_ok('Test::Conf::Yaml'); 
}
require_ok('Test::Conf::Yaml');

#### INTERNAL MODULES
use Test::Conf::Yaml;

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

BEGIN {
    use_ok('Conf::Yaml');
    use_ok('Test::Conf::Yaml');
}
require_ok('Conf::Yaml');
require_ok('Test::Conf::Yaml');

my $object = Test::Conf::Yaml->new({
    log			=>	$log,
    printlog    =>  $printlog
});

#### TEST LOAD FILE
$object->testRead();

### TEST GET KEY
$object->testInsertToHash();

#### TEST GET KEY
$object->testGetKey();

### TEST SET KEY
$object->testSetKey();

#### TEST READ FROM MEMORY
$object->testReadFromMemory();

### TEST WRITE TO MEMORY
$object->testWriteToMemory();

