package Conf::Common;
use Moose::Role;
use Method::Signatures::Simple;

=head2

	PACKAGE		Conf::Common

  PURPOSE
    
    PROVIDE SUPPORTING METHODS TO Conf CLASSES		
	
=cut


#### EXTERNAL
use Data::Dumper;

#### INTERNAL
use Util::Main;

# Booleans
has 'memory'  		=>  ( 	isa => 'Bool', 	is => 'rw',	default	=>	0 );

# String
has 'inputfile'  	=>  ( 	isa => 'Str|Undef', is => 'rw' );

# has 'util' 	=> (
# 	is 		=>	'rw',
# 	isa 	=> 	'Util::Main',
# 	default	=>	method {	Util::Main->new();	}
# );

#### STUBS
method hasKey {}
method getKey {}
method setKey {}
method getKeys {}
method removeKey {}

method setSlots ( $arguments ) {
	#### ADD ARGUMENT VALUES TO SLOTS
	if ( $arguments )
	{
		foreach my $key ( keys %{$arguments} )
		{
			$arguments->{$key} = $self->unTaint($arguments->{$key});
			$self->$key($arguments->{$key}) if $self->can($key);
		}
	}	
}

method unTaint ( $input ) {
	return if not defined $input;
	
	$input =~ s/;.*$//g;
	$input =~ s/`.*$//g;
	
	return $input;
}


method makeBackup ( $file ) {

=head2

	SUBROUTINE 		makeBackup
	
	PURPOSE
	
		COPY FILE TO NEXT NUMERICALLY-INCREMENTED BACKUP FILE

=cut
	$self->logWarning("file not defined") if not defined $file;
	
	#### BACKUP FSTAB FILE
	my $counter = 1;
	my $backupfile = "$file.$counter";
	while ( -f $backupfile )
	{
		$counter++;
		$backupfile = "$file.$counter";
	}
	$self->logNote("backupfile", $backupfile);

	require File::Copy;
	File::Copy::copy($file, $backupfile);
};


1;
