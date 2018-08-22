use MooseX::Declare;

#### INTERNAL
use Util::Main;

class Test::Conf::Yaml extends Conf::Yaml with (Test::Common) {

#### EXTERNAL MODULES
use Test::More;
use JSON;
use Data::Dumper;
use FindBin qw($Bin);

has 'util'		=>	(
	is 			=>	'rw',
	isa 		=>	'Util::Main',
	lazy		=>	1,
	builder	=>	"setUtil"
);

method setUtil () {
	my $util = Util::Main->new({
		log				=>	$self->log(),
		printlog	=>	$self->printlog()
	});

	$self->util($util);	
}

method testRead {
	diag("#### read");
	
	my $inputfile			=	"$Bin/inputs/config.yml";
	my $logfile				=	"$Bin/outputs/read/read.log";	
	my $expectedfile	=	"$Bin/inputs/read/config.json";
	my $expectedjson	=	$self->util()->getFileContents($expectedfile);

	my $expected = JSON->new()->decode($expectedjson);
	$self->logDebug("expected", $expected);
	
	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	my $yaml 		= 	$self->yaml();
	$self->logDebug("yaml", $yaml);
	
	is_deeply($yaml->[0], $expected);
}


method testInsertToHash {
	diag("getKey");
	
	my $inputfile	=	"$Bin/inputs/config.yml";
	my $logfile		=	"$Bin/outputs/getkey/getkey.log";	
	my $expectedfile=	"$Bin/inputs/getkey/config.json";
	my $expectedjson=	$self->util()->getFileContents($expectedfile);

	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	my $tests	=	[
		{
			name		=>	"two-level hash",
			hash		=>	{
				vagrant	=> {
					BASEDIR => "/data/vagrant"
				}
			},
			keys		=>	["vagrant", "TESTKEY"],
			value		=>	"TESTVALUE",
			expected	=> 	{
				vagrant	=> {
					BASEDIR => "/data/vagrant",
					TESTKEY	=>	"TESTVALUE"
				}
			}
		}
		,
		{
			name		=>	"three-level hash",
			hash		=>	{
				vagrant	=> {
					BASEDIR => "/data/vagrant"
				}
			},
			keys		=>	["vagrant", "TESTKEY", "ARRAY"],
			value		=>	["entry1", "entry2"],
			expected	=> 	{
				vagrant	=> {
					BASEDIR => "/data/vagrant",
					TESTKEY	=>	{
						"ARRAY"	=> ["entry1", "entry2"]
					}
				}
			}
		}
	];

	foreach my $test ( @$tests ) {

		my $name	=	$test->{name};
		my $hash	=	$test->{hash};
		my $keys	=	$test->{keys};
		my $value	=	$test->{value};
		my $actual	=	$self->insertToHash($hash, $keys, $value);
		$self->logDebug("actual", $actual);
		my $expected=	$test->{expected};
		$self->logDebug("expected", $expected);
		
		is_deeply($actual, $expected, $name);
	}	
}

method testGetKey {
	diag("getKey");
	
	my $inputfile	=	"$Bin/inputs/config.yml";
	my $logfile		=	"$Bin/outputs/getkey/getkey.log";	
	my $expectedfile=	"$Bin/inputs/getkey/config.json";
	my $expectedjson=	$self->util()->getFileContents($expectedfile);

	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	my $tests	=	[
		{
			name		=>	"scalar, no subkey",
			key			=>	"username",
			expected	=>	"billy",
		}
		,
		{
			name		=>	"array, no subkey",
			key			=>	"error_emails",
			expected	=>	[
				"BATMAN\@batcave.com",
				"ROBIN\@batcave.com"
			]
		}
		,
		{
			name		=>	"hash, no subkey",
			key			=>	"fasta_locations",
			expected	=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"scalar, subkey",
			key			=>	"test:TESTUSER",
			expected	=>	"testuser"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"data:aquarius-8:JBROWSEDATA",
			expected	=>	"/data/jbrowse/species"
		}
	];

	foreach my $test ( @$tests ) {
		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $value	=	$self->getKey($key);
		my $expected=	$test->{expected};
		
		is_deeply($value, $expected, $name);
	}
}


method testSetKey {
	diag("setKey");

	#### SET LOGFILE
	my $logfile		=	"$Bin/outputs/setkey/setkey.log";	
	$self->logfile($logfile);
	
	my $tests	=	[
		{
			name		=>	"scalar, one level",
			key			=>	"username",
			value		=>	"nobody",
			inputfile	=>	"$Bin/inputs/setkey/config.yml",
			outputfile	=>	"$Bin/outputs/setkey/scalar-one-level",
			expectedfile=>	"$Bin/inputs/setkey/scalar-one-level"
		}
		,
		{
			name		=>	"array, one level",
			key			=>	"error_emails",
			value		=>	[
				"HEMAN\@universe.com",
				"GREYSKULL\@universe.com"
			],
			inputfile	=>	"$Bin/inputs/setkey/config.yml",
			outputfile	=>	"$Bin/outputs/setkey/array-one-level",
			expectedfile=>	"$Bin/inputs/setkey/array-one-level"
		}
		,
		{
			name		=>	"hash, one level",
			key			=>	"TEMP_FASTA",
			value		=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			},
			inputfile	=>	"$Bin/inputs/setkey/config.yml",
			outputfile	=>	"$Bin/outputs/setkey/hash-one-level",
			expectedfile=>	"$Bin/inputs/setkey/hash-one-level"
		}
		,
		{
			name		=>	"scalar, two level",
			key			=>	"test:TESTUSER",
			value		=>	"nobody",
			inputfile	=>	"$Bin/inputs/setkey/config.yml",
			outputfile	=>	"$Bin/outputs/setkey/scalar-two-level",
			expectedfile=>	"$Bin/inputs/setkey/scalar-two-level"
		}
		,
		{
			name		=>	"scalar, three level",
			key			=>	"data:aquarius-8:JBROWSEDATA",
			value		=>	"/data/jbrowse/species",
			inputfile	=>	"$Bin/inputs/setkey/config.yml",
			outputfile	=>	"$Bin/outputs/setkey/scalar-three-level",
			expectedfile=>	"$Bin/inputs/setkey/scalar-three-level"
		}
		,
		{
			name		=>	"array, three level",
			key			=>	"aws:info:ZONES",
			value		=>	["us-east-1a", "us-east-1b"],
			inputfile	=>	"$Bin/inputs/setkey/config.yml",
			outputfile	=>	"$Bin/outputs/setkey/array-three-level",
			expectedfile=>	"$Bin/inputs/setkey/array-three-level"
		}
	];

	foreach my $test ( @$tests ) {
		my $name			=	$test->{name};
		my $key				=	$test->{key};
		my $value			=	$test->{value};
		my $inputfile		=	$test->{inputfile};
		my $outputfile		=	$test->{outputfile};
		my $expectedfile	=	$test->{expectedfile};
		$self->logDebug("value", $value);
			
		#### COPY FILE
		`rm -fr $outputfile`;
		`cp $inputfile $outputfile`;
		
		#### LOAD SLOTS AND READ FILE	
		$self->inputfile($outputfile);
		$self->read($outputfile);

		$self->logDebug("self->memory", $self->memory());
		
		$self->setKey($key, $value);
		
		#### CHECK VALUE
		my $actual	=	$self->getKey($key);
		$self->logDebug("actual", $actual);
		is_deeply($actual, $value, "$name: $value");

		#### CHECK OUTPUTFILE
		my $diff = $self->diff($outputfile, $expectedfile);
		$self->logDebug("diff", $diff);
		ok($diff == 1, "$name (outputfile)");
	}
}

method testReadFromMemory {
	diag("readFromMemory");
	
	my $inputfile	=	"$Bin/inputs/config.yml";
	my $expectedfile=	"$Bin/inputs/config.expected.yaml";
	my $logfile		=	"$Bin/outputs/memory/memory.log";	
	
	#### SET MEMORY
	$self->memory(1);
	
	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);
	
	#### INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");	

	my $tests	=	[
		{
			name		=>	"one-level key, scalar",
			key			=>	"username",
			expected	=>	"billy",
		}
		,
		{
			name		=>	"one-level key, array",
			key			=>	"error_emails",
			expected	=>	[
				"BATMAN\@batcave.com",
				"ROBIN\@batcave.com"
			]
		}
		,
		{
			name		=>	"one-level key, hash",
			key			=>	"fasta_locations",
			expected	=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"one-level key, scalar",
			key			=>	"test:TESTUSER",
			expected	=>	"testuser"
		}
		,
		{
			name		=>	"three-level key, scalar",
			key			=>	"data:aquarius-8:JBROWSEDATA",
			expected	=>	"/data/jbrowse/species"
		}
	];

	foreach my $test ( @$tests ) {
		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $value	=	$self->getKey($key);
		my $expected=	$test->{expected};
		
		is_deeply($value, $expected, $name);
	}

	#### MAKE SURE INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");
}

method testWriteToMemory {
	diag("writeToMemory");
	
	my $inputfile	=	"$Bin/inputs/config.yml";
	my $expectedfile=	"$Bin/inputs/config.expected.yaml";
	my $outputfile	=	"$Bin/outputs/memory/config.yml";
	my $logfile		=	"$Bin/outputs/memory/memory.log";
	$self->logDebug("outputfile", $outputfile);
	
	#### SET MEMORY
	$self->memory(1);
	
	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->outputfile($outputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	#### MAKE SURE OUTPUT FILE NOT PRINTED
	$self->write($outputfile);
	my $found =	 -f $outputfile;
	$self->logDebug("found", $found);
	is_deeply($found, undef, "outputfile not printed");

	#### MAKE SURE INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");	
	
	my $tests	=	[
		{
			name		=>	"scalar, one level",
			key			=>	"username",
			value		=>	"nobody",
		}
		,
		{
			name		=>	"array, one level",
			key			=>	"error_emails",
			value		=>	[
				"HEMAN\@universe.com",
				"GREYSKULL\@universe.com"
			]
		}
		,
		{
			name		=>	"hash, one level",
			key			=>	"TEMP_FASTA",
			subkey		=>	undef,
			value		=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"scalar, two level",
			key			=>	"test:TESTUSER",
			value		=>	"testuser"
		}
		,
		{
			name		=>	"scalar, three level",
			key			=>	"data:aquarius-8:JBROWSEDATA",
			value	=>	"/data/jbrowse/species"
		}
		,
		{
			name		=>	"scalar, three level",
			key			=>	"aws:info:AWS_USER_ID",
			value		=>	"1234567890"
		}
	];

	foreach my $test ( @$tests ) {
		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $subkey	=	$test->{subkey};
		my $value	=	$test->{value};
		$self->setKey($key, $value);

		my $expected=	$self->getKey($key);
		$self->logDebug("expected", $expected);
		
		is_deeply($value, $expected, "$name: $value");
	}

	#### MAKE SURE INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");	
}


}