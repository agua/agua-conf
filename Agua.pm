use MooseX::Declare;

class Conf::Agua extends Conf::Ini {
    
use Data::Dumper;

# Integers
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# String
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'logfile'  	    =>  ( isa => 'Str|Undef', is => 'rw' );
has 'separator'		=>	(	is	=>	'rw',	isa	=> 	'Str'	);

=head2

	PACKAGE		Conf::Agua

    PURPOSE
    
        READ AND WRITE ini-FORMAT CONFIGURATION FILES
		
=cut

method BUILD ($hash) {
    $self->initialise();
}

method initialise () {

	$self->logDebug("");
}



}

