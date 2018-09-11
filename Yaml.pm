use MooseX::Declare;
use Method::Signatures::Modifiers;

=head2

	PACKAGE		Conf::Yaml

  PURPOSE
    
    1. READ AND WRITE YAML-FORMAT FILES. E.G.:

			#qc quality of cancer samples
			build_qc_cancer_samples:
				gt_gen_concordance:
					- ge
					- 0.991
			
			error_emails:
				- anyusername@illumina.com
	
=cut



class Conf::Yaml with (Conf::Common, Util::Logger) {

use YAML::Tiny;
use JSON;

# Bool
has 'memory'		=> ( isa => 'Bool', 	is => 'rw', default	=> 	0);
has 'backup'		=> ( isa => 'Bool', 	is => 'rw', default	=> 	1);

# Int
has 'valueoffset'	=>  ( isa => 'Int', is => 'rw', default => 24 );
has 'log'			=>  ( isa => 'Int', is => 'rw', default => 4 );
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# String
has 'inputfile' 	=>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'outputfile' 	=> (	is	=>	'rw',	isa	=>	'Str'	);

# Object
has 'memorystore'	=> ( isa => 'HashRef|Undef', is => 'rw', required => 0, default	=> 	undef );
has 'yaml' 	=> (
	is 		=>	'rw',
	isa 	=> 	'YAML::Tiny',
	default	=>	method {	YAML::Tiny->new();	}
);
method BUILD ($arguments) {
	$self->initialise($arguments);
}

method initialise ($arguments) {
	$self->setSlots($arguments);

	if ( defined $self->inputfile() and not defined $self->outputfile() ) {
		$self->outputfile($self->inputfile());	
	}
}

method read ($inputfile) {
=head2

	SUBROUTINE 		read
	
	PURPOSE
	
		READ CONFIG FILE AND STORE VALUES
		
=cut

	#$self->logCaller();
	$self->logNote("inputfile", $inputfile);
	$self->logNote("self->memory()", $self->memory());
	
	#### SET memorystore IF memory
	if ( $self->memory() ) {
		if ( defined $self->memorystore() ) {
			return $self->readFromMemory();
		}
		else {
			my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;

			$self->yaml($yaml);
			
			$self->memorystore($$yaml[0]);
		}
	}
	else {
		#open(FILE, "<", $inputfile) or die "Can't open inputfile: $inputfile\n";
		my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;
		
		$self->yaml($yaml);
	}
}

method write ($file) {
	$self->logNote("file", $file);
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	
	#$self->logNote("FINAL file", $file);
	
	my $yaml 		=	$self->yaml();
	#$self->logNote("yaml", $yaml);

	my $memory = $self->memory();
	$self->logNote("memory", $memory);
	
	return $self->writeToMemory($$yaml[0]) if $self->memory();

	return $yaml->write($file);
}

method getKey ($key) {
	#$self->logCaller();
	$self->logNote("key", $key);
	
	$self->read($self->inputfile());

	my $keys = [ split ":", $key ];
	
	return $self->_getKey($keys);
}

method _getKey ($keys) {
	$self->logNote("keys", $keys);

	my $yaml 		= 	$self->yaml();
	return undef if not defined $yaml or not @$yaml;
	my $hash = $yaml->[0];
	$self->logNote("hash", $hash);
	
	foreach my $key ( @$keys ) {
		$hash  = $hash->{$key};
		return undef if not defined $hash;
		$self->logNote("data", $hash);
	}
	
	return $hash;
}

method setKey ($key, $value) {
	$self->logNote("key", $key);
	$self->logNote("value", $value);
	$self->read($self->inputfile());

	my $keys = [ split ":", $key ];	

	$self->_setKey($keys, $value);

	$self->write($self->outputfile());
}

method _setKey ($keys, $value) {
	$self->logNote("keys", $keys);
	$self->logNote("value", $value);

	my $yaml 		= 	$self->yaml();
	return undef if not defined $yaml or not @$yaml;
	my $hash = $yaml->[0];
	$self->logNote("PRESET hash", $hash);

	my $parser = JSON->new();
	if ( $value =~ /^\{/ or $value =~ /^\[/ ) {
		$value = $parser->decode($value);
	}
	$self->logNote("value", $value);

	my $counter = 0;
	$hash = $self->insertToHash($hash, $keys, $value);
	#foreach my $key ( @$keys ) {
	#	$hash  = $hash->{$key};
	#	return undef if not defined $hash;
	#	$self->logNote("hash", $hash);
	#}
	
	$self->logNote("POSTSET hash", $hash);
	
	$yaml->[0] = $hash;
	$self->logNote("returning yaml", $yaml);
	
	$self->yaml($yaml);
}

method insertToHash ($hash, $keys, $value) {
	#$self->logNote("hash", $hash);
	#$self->logNote("keys", $keys);
	#$self->logNote("value", $value);
	
	my $key = shift @$keys;
	if ( scalar(@$keys) ) {
		$hash->{$key} = $self->insertToHash( \%{$hash->{$key}}, $keys, $value);
	}
	else {
		$hash->{$key} = $value;
	}
	#$self->logNote("returning hash", $hash);

	return $hash;
}

method removeKey ($key) {
	$self->logNote("key", $key);

	$self->_removeKey($key);
	
	$self->write($self->outputfile());
}

method _removeKey ($key) {
	$self->logNote("key", $key);

	return if not defined $self->yaml()->[0]->{$key};
	
	return delete $self->yaml()->[0]->{$key};
}

method writeToMemory ($hash) {
	$self->logNote();
	#$self->logNote("hash", $hash);
	
	$self->memorystore($hash);
}

method readFromMemory {
	$self->logNote();
	
	$self->yaml()->[0] = $self->memorystore();
}


}	#### Conf::Yaml