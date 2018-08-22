use MooseX::Declare;
#use Method::Signatures::Simple;

=head2

	PACKAGE		Conf::StarCluster

    PURPOSE
    
        1. READ AND WRITE STARCLUSTER ini-FORMAT CONFIGURATION FILES
			
=cut

class Conf::StarCluster extends Conf::Ini {

#use Data::Dumper;

has 'spacer'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"="		);
has 'separator'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"="		);
has 'comment'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"#"		);


}

1;


