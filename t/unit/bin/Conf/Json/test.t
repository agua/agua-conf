#!/usr/bin/perl -w

=head2

APPLICATION		test.t

PURPOSE

	TEST PACKAGE Conf::Json

        1. READ JSON ARRAY-FORMAT CONFIGURATION FILES (PRETTY FORMAT)

		2. ADD/EDIT/REMOVE ENTRIES
		
		3. WRITE TO OUTFILE PRESERVING ORDER OF KEYS

USAGE		./Configure.t [Int --log] [Int --printlog] [--help]

		--log		Displayed log level (1-5)	
		--printlog		Logfile log level (1-5)	
		--help			Show this message

=cut

use Test::More	tests => 18;
use Getopt::Long;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use lib "$Bin/../../../../../..";

BEGIN {
    use_ok('Test::Conf::Json'); 
}
require_ok('Test::Conf::Json');

#### INTERNAL MODULES
use Test::Conf::Json;

#### SET LOGFILE
my $logfile     =   "$Bin/outputs/test.log";
my $log         =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $inputfile = "$Bin/inputs/trackData.json";
my $outputfile = "$Bin/outputs/trackData.json";

my $object = Test::Conf::Json->new({
    logfile		=> $logfile,
	inputfile	=>	$inputfile,
	backup		=>	0,
	log			=>	$log,
	printlog	=>	$printlog
});

#### READ, WRITE, SECTION ORDER AND CONTENTS
$object->testRead($object, $inputfile);
$object->testWrite($object, $inputfile, $outputfile);
$object->testGetSectionOrder($object, $inputfile);
$object->testGetKey($object);
$object->testInsertKey($object);

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}
