use MooseX::Declare;

class Conf::Ini with (Conf::Common, Util::Logger) {

# Integers
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# String
has 'valueoffset'		=>  ( isa => 'Int', is => 'rw', default => 24 );  
has 'outputfile'	=>	(	isa	=> 	'Str',	is	=>	'rw'	);
has 'username'  	=>  ( 	isa	=> 	'Str',	is	=>	'rw'	);
has 'separator'		=>	(	isa	=> 	'Str',	is	=>	'rw'	);
has 'ignore' 		=>	(	isa	=> 	'Str',	is	=>	'rw',	default	=>	"#;\\[?"	);
has 'spacer' 		=>	(	isa	=> 	'Str',	is	=>	'rw',	default	=>	"\\t=\\s"	);
has 'logfile'  	    =>  ( 	isa => 	'Str|Undef', is => 'rw' );

# Object
has 'sections'		=>	(	is 	=>	'rw', 	isa =>	'ArrayRef|Undef' );

####////}}}}

#### BUILD
method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( $args ) {
			$self->$arg($args->{$arg}) if $self->can($arg);
		}
	}
	$self->logDebug("args", $args);
}

=head2

	PACKAGE		Conf::Ini

    PURPOSE
    
        READ AND WRITE ini-FORMAT CONFIGURATION FILES
		
=cut

method getSeparator ( $key ) {
	return $self->separator() if defined $self->separator();
	
	my $separator = $self->valueoffset() - length($key);
	$separator = 4 if $separator < 4;

	return " " x $separator;
}

=head2

	SUBROUTINE 		read
	
	PURPOSE
	
		1. IF NO section IS PROVIDED, RETURN A HASH OF {section => {KEY-VALUE PAIRS}} PAIRS
		
		2. IF NO key IS PROVIDED, RETURN A HASH OF KEY-VALUE PAIRS FOR THE section
		
		3. RETURN THE KEY-VALUE PAIR FOR THE section AND key
		
		4. RETURN IF THE GIVEN section IS NOT IN THE ini FILE
		
		5. RETURN IF THE GIVEN key IS NOT IN THE ini FILE

=cut
method read ( $file ) {
	$self->logNote("PASSED file", $file);

	#### RETURN SECTIONS IF memory
	return $self->readFromMemory() if $self->memory() and defined $self->sections();
	
	$file = $self->inputfile() if not defined $file;
	$self->inputfile($file) if defined $file;
	$self->logNote("file after inputfile()", $file);
	
	$file = $self->outputfile() if not defined $file;
	#$self->logNote("file after outputfile()", $file);

	$self->logNote("file ", $file);

	return if not defined $file;
	
	#### SKIP READ IF FILE ABSENT
	my $sections = [];
	my ($dir) = $file =~ /^(.+)\/([^\/]+)$/;
	if ( not -d $dir )
	{
		$self->logNote("not -d $dir. Returning sections", $sections);
		return $sections;	
	}
	$self->logNote("not -f $file. Returning sections: ", $sections) if not -f $file;
	return $sections if not -f $file;

	my $old = $/;
	$/ = undef;
	open(FILE, $file) or die "Conf::read    Can't open file: $file\n";
	my $contents = <FILE>;
	close(FILE) or die "Conf::read    Can't close file: $file\n";

	my @sections = split "\\n\\[", $contents;
	return [] if not @sections;
	shift @sections if not $sections[0] =~ s/^\s*\[//;

	my $counter = 0;
	foreach my $section ( @sections )
	{
		$counter++;
		#$self->logNote("Doing section $counter");
		
		$section =~ /^(.+?)(\s+.+)?\s*\]/;
		my $section_key = $1;
		my $section_value = $2;
		$section_value =~ s/^\s+// if defined $section_value;
		my @lines = split "\n", $section;
		shift @lines;
		my $section_hash;
		$section_hash->{key} = $section_key;
		$section_hash->{value} = $section_value;
		
		my $line_comment = '';
		foreach my $line ( @lines )
		{
			my ($key, $value, $comment) = $self->parseline($line);
			#$self->logNote("$key\t=>\t$value");
			#$self->logNote("comment: **$comment**");

			#### STORE COMMENT IF PRESENT
			$line_comment .= "$comment\n" if defined $comment;
			
			#### ADD KEY-VALUE PAIR TO SECTION HASH
			if ( defined $key )
			{
				$section_hash->{keypairs}->{$key}->{value} = $value ;
	
				#### ADD COMMENT IF PRESENT
				$line_comment =~ s/\s+$//;
				$section_hash->{keypairs}->{$key}->{comment} = $line_comment if $line_comment;
				$line_comment = '';
			}
		}
		push @$sections, $section_hash;
	}
	$/ = $old;

	return $sections;
}

method write ( $sections, $file ) {

	$self->logNote("file)");
	$self->logNote("file", $file);
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	
	$self->logNote("FINAL file", $file);
	my $memory = $self->memory();
	$self->logNote("memory", $memory);

	return $self->writeToMemory($sections) if $self->memory();

	#$self->logNote("BEFORE self->_getSections()");
	$sections = $self->_getSections() if not defined $sections;
	#$self->logNote("file", $file);
	#$self->logNote("sections", $sections);
	
	#### SANITY CHECK
	$self->logWarning("file not defined") if not defined $file;
	$self->logWarning("sections not defined") if not defined $sections;
	
	#### KEEP COPIES OF FILES IF backup DEFINED
	$self->makeBackup($file) if $self->backup();

	#### CREATE FILE DIR IF NOT EXISTS	
	my ($dir) = $file =~ /^(.+)\/([^\/]+)$/;
	File::Path::mkpath($dir) if not -d $dir;
	$self->logNote("Can't create dir", $dir) if not -d $dir;

	open(OUT, ">$file") or die "Conf::write    Can't open file: $file\n";
	foreach my $section ( @$sections ) {
		my $section_key = $section->{key};
		my $section_value = $section->{value};
		#$self->logNote("section_key", $section_key);
		#$self->logNote("section_value", $section_value);
		
		my $header = "[" . $section_key;
		$header .= " $section_value" if defined $section_value;
		$header .= "]\n";
		print OUT $header;
		#$self->logNote("header", $header);

		my $keypairs = $section->{keypairs};
		#$self->logNote("keypairs:");
		
		my @keys = keys %$keypairs;
		@keys = sort @keys;
		foreach my $key ( @keys ) {
			my $comment = $keypairs->{$key}->{comment};
			my $value = $keypairs->{$key}->{value};
			my $entry = '';
			$entry .= "\n" . $comment . "\n" if defined $comment;
			$entry .= $key . $self->getSeparator($key) . $value . "\n";
			#$self->logNote("entry", $entry);
			print OUT $entry;
		}
		print OUT "\n";
	}
	close(OUT) or die "Can't close file: $file\n";

	#$self->logNote("Completed write file", $file);
};

=head2

	SUBROUTINE 		parseline
	
	PURPOSE
	
		1. PARSE A KEY-VALUE PAIR FROM LINE
		
		2. RETURN A COMMENT AS A THIRD VALUE IF PRESENT

=cut
method parseline ( $line ) {
	#$self->logNote("line", $line);
	
	my $ignore	=	$self->ignore();
	my $spacer	=	$self->spacer();
	#$self->logNote("ignore", $ignore);
	#$self->logNote("spacer", $spacer);

	#$self->logNote("ignoring line", $line) if $line =~ /^[$ignore]/;
	return (undef, undef, $line) if $line =~ /^[$ignore]+/;
	
	my ($key, $value) = $line =~ /^(.+?)[$spacer]+(.+)\s*$/;
	
	
	
	#### DEFINE VALUE AS '' FOR BOOLEAN key (I.E., ITS A FLAG)
	$value = '' if not defined $value;

	return ($key, $value);	
};

=head2

=head3 C<SUBROUTINE 		conf>
	
	PURPOSE
	
		RETURN A SIMPLE HASH OF CONFIG KEY-VALUE PAIRS

=cut
method conf ( $file ) {
	
	$file = $self->inputfile() if not defined $file;
	return if not defined $file;
	
	$self->logNote("");
	$self->logNote("file", $file);
	my $hash = {};
	open(FILE, $file) or die "Can't open file: $file\n";
	my @lines = <FILE>;
	close(FILE) or die "Can't close file: $file\n";
	foreach my $line ( @lines )
	{
		$self->logNote("line", $line);
		my ($key, $value) = $self->parseline($line);
		$self->logNote("$key\t=>\t$value");
	
		$hash->{$key} = $value if defined $key;
	}

	return $hash;
};


=head2

	SUBROUTINE 		makeBackup
	
	PURPOSE
	
		COPY FILE TO NEXT NUMERICALLY-INCREMENTED BACKUP FILE

=cut
method makeBackup ( $file ) {
	
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


=head2

	SUBROUTINE 		getSectionKeys
	
	PURPOSE
	
		RETURN THE KEY-VALUE PAIRS FOR ALL SECTION HEADINGS IN THE INPUTFILE
		
=cut
method getSectionKeys {
	my $sections = $self->_getSections();
	
	my $sectionkeys = [];
	foreach my $section ( @$sections ) {
		my $keypair = $section->{key};
		$keypair .= ":" . $section->{value} if defined $section->{value};
		push @$sectionkeys, $keypair;
	}
	$self->logNote("sectionkeys", $sectionkeys);
	
	return $sectionkeys;
}


method getKeys ( $section_keypair ) {
	my ($key, $value) = $section_keypair =~ /^([^:]+):?(.*)$/;
	$self->logNote("key", $key);
	$self->logNote("value", $value);
	my $sections = $self->read();
	my $section = $self->_getSection($sections, $key, $value);
	my @keys = keys ( %{$section->{keypairs}} );
	@keys = sort @keys;
	
	return \@keys;
}

=head2

	SUBROUTINE 		_getSections
	
	PURPOSE
	
		RETURN ALL SECTIONS IN THE INPUTFILE
		
=cut
method _getSections {
	
	$self->logNote("");
	return $self->sections() if defined $self->sections();
	$self->logNote("sections not defined. Doing read()");
	my $sections = $self->read();
	$self->sections($sections);
	$self->logNote("sections", $sections);

	return $sections;
}

=head2

	SUBROUTINE 		_getSection
	
	PURPOSE
	
		1. RETURN A SECTION WITH THE GIVEN NAME (AND VALUE IF PROVIDED)
		
=cut
method _getSection ( $sections, $name, $value ) {
	$self->logNote("name, value)");
	$self->logNote("name", $name);
	$self->logNote("value", $value);
	
	#### SANITY CHECK
	$self->logWarning("sections not defined") if not defined $sections;
	$self->logWarning("name not defined") if not defined $name;

	#### SEARCH FOR SECTION AND ADD KEY-VALUE PAIR IF FOUND	
	foreach my $section ( @$sections )
	{
		#$self->logNote("section", $section);

		next if not $section->{key} eq $name;
		next if defined $value and defined $section->{value}
			and not $section->{value} eq $value;
		
		#$self->logNote("RETURNING section", $section);
		
		return $section;
	}

	return {};
}

=head2

	SUBROUTINE 		_addSection
	
	PURPOSE
	
		1. ADD A SECTION
		
		2. ADD THE SECTION'S VALUE IF DEFINED
		
=cut
method _addSection ( $sections, $name, $value ) {
	$self->logNote("sections", $sections);
	$self->logNote("name", $name);
	$self->logNote("value", $value);

	#### SANTIY CHECK
	$self->logWarning("sections not defined") if not defined $sections;
	$self->logWarning("name not defined") if not defined $name;

	$value = '' if not defined $value;
	my $section;
	$section->{key} = $name;
	$section->{value} = $value;
	push @$sections, $section;

	return $section;
}


method hasKey {	
	return 1 if defined $self->getKey(@_);
	return 0;
}

method getKey ( $section_keypair, $key ) {
	my ($name, $value) = $section_keypair =~ /^([^:]+):?(.*)$/;
	$self->logWarning("name not defined") if not defined $name;
	$self->logWarning("key not defined") if not defined $key;
	
	$self->logNote("section_keypair not defined");
	$self->logNote("section_keypair", $section_keypair);
	$self->logNote("name", $name);
	$self->logNote("value", $value);
	$self->logNote("key", $key);

	my $sections = $self->read();

	my $section = $self->_getSection($sections, $name, $value);
	$self->logNote("section", $section);

	return $self->_getKey($section, $key);
}

=head2

	SUBROUTINE 		_getKey
	
	PURPOSE
	
		1. ADD A KEY-VALUE PAIR TO A SECTION
		
		2. RETAIN ANY EXISTING COMMENTS IF comment NOT DEFINED
		
		3. ADD COMMENTS IF comment DEFINED
		
=cut
method _getKey ( $section, $key ) {
	$self->logNote("key", $key);
	#$self->logNote("section", $section);

	#### SANITY CHECK
	$self->logWarning("section not defined") if not defined $section;
	$self->logWarning("key not defined") if not defined $key;
	
	$self->logNote("Returning", $section->{keypairs}->{$key}->{value});

	return $section->{keypairs}->{$key}->{value};
}


=head2

	SUBROUTINE 		_sectionIsEmpty
	
	PURPOSE
	
		1. RETURN 1 IF SECTION CONTAINS NO KEY-VALUE PAIRS
		
		2. OTHERWISE, RETURN 0
		
=cut
method _sectionIsEmpty ( $section ) {

	$self->logNote("section", $section);
	
	#### SANITY CHECK
	$self->logWarning("section not defined") if not defined $section;
	
	return 1 if not defined $section->{keypairs};
	my @keys = keys %{$section->{keypairs}};
	return 1 if not @keys;
	
	return 0;
}


=head2

	SUBROUTINE 		_removeSection
	
	PURPOSE
	
		1. REMOVE A SECTION FROM THE CONFIG OBJECT
		
=cut
method _removeSection ( $sections, $section ) {

	$self->logNote("section)");
	$self->logNote("sections", $sections);
	$self->logNote("section", $section);
	
	#### SANITY CHECK
	$self->logWarning("sections not defined") if not defined $sections;
	$self->logWarning("section not defined") if not defined $section;

	#### SEARCH FOR SECTION AND REMOVE IF FOUND	
	for ( my $i = 0; $i < @$sections; $i++ )
	{
		my $current_section = $$sections[$i];
		next if not $current_section->{key} eq $section->{key};
		next if defined $section->{value} and not $current_section->{value} eq $section->{value};
		splice(@$sections, $i, 1);
		return 1;
	}

	return 0;
}

=head2

	SUBROUTINE 		setKey
	
	PURPOSE
	
		1. ADD A SECTION AND KEY-VALUE PAIR TO THE CONFIG
		
			FILE IF THE SECTION DOES NOT EXIST
		
		2. OTHERWISE, ADD A KEY-VALUE PAIR TO AN EXISTING SECTION

		3. REPLACE KEY ENTRY IF IT ALREADY EXISTS IN THE SECTION
		
=cut
method setKey ( $section_keypair, $key, $value, $comment ) {

	$self->logDebug("section_keypair", $section_keypair);
	$self->logDebug("key", $key);
	$self->logDebug("value", $value);
	
	my ($section_name, $section_value) = $section_keypair =~ /^([^:]+):?(.*)$/;
	$self->logWarning("section_name not defined") if not defined $section_name;
	$self->logWarning("key not defined") if not defined $key;
	$self->logNote("key, value, comment)");

	#### SET SECTION VALUE TO UNDEF IF EMPTY
	$section_value = undef if defined $section_value and not $section_value;

	#### SET VALUE TO '' IF UNDEFINED
	$value = '' if not defined $value;
	
	$self->logNote("section_name", $section_name);
	$self->logNote("section_value", $section_value);
	$self->logNote("key", $key);
	$self->logNote("value", $value);
	$self->logNote("comment", $comment);
	
	#### SANITY CHECK
	$self->logWarning("section_name not defined") if not defined $section_name;
	$self->logWarning("key not defined") if not defined $key;
	$self->logWarning("value not defined for key: $key") if not defined $value;

	#### SEARCH FOR SECTION AND ADD KEY-VALUE PAIR IF FOUND	
	my $sections = $self->_getSections();
	$self->logNote("sections", $sections);
	$self->logDebug("sections length", scalar(@$sections)) if defined $sections;

	my $matched = 0;
	foreach my $current_section ( @$sections )
	{
		next if not $current_section->{key} eq $section_name;
		next if defined $section_value and not $current_section->{value} eq $section_value;
		$matched = 1;
		$self->_setKey($current_section, $key, $value, $comment);
		last;
	}
	$self->logNote("Can't find section", $section_name) if not $matched;
	
	#### OTHERWISE, CREATE THE SECTION AND ADD THE 
	#### KEY-VALUE PAIR TO IT
	if ( not $matched )
	{
		$self->logNote("Creating section", $section_name);
		my $section = $self->_addSection($sections, $section_name, $section_value);
		#$self->logNote("section", $section);
		$self->logNote("section->key", $section->{key});
		$self->_setKey($section, $key, $value, $comment);
	}
	
	#$self->logNote("sections", $sections);
	$self->logDebug("sections length", scalar(@$sections)) if defined $sections;

	$self->write($sections);
}

=head2

	SUBROUTINE 		_setKey
	
	PURPOSE
	
		1. ADD A KEY-VALUE PAIR TO A SECTION
		
		2. RETAIN ANY EXISTING COMMENTS IF comment NOT DEFINED
		
		3. ADD COMMENTS IF comment DEFINED
		
=cut
method _setKey ( $section, $key, $value, $comment ) {
	$self->logNote("key, value)");
	$self->logNote("section", $section);
	$self->logNote("key", $key);
	$self->logNote("value", $value);

	#### SANITY CHECK
	$self->logWarning("section not defined") if not defined $section;
	$self->logWarning("key not defined") if not defined $key;
	$self->logWarning("value not defined") if not defined $value;
	
	$section->{keypairs}->{$key}->{value} = $value;
	$section->{keypairs}->{$key}->{comment} = $self->comment() . " " . $comment if defined $comment;
}

=head2

	SUBROUTINE 		removeKey
	
	PURPOSE
	
		1. ADD A SECTION AND KEY-VALUE PAIR IF SECTION DOES NOT EXIST
		
		2. ADD A KEY-VALUE PAIR TO AN EXISTING SECTION

		3. REPLACE KEY ENTRY IF IT ALREADY EXISTS IN THE SECTION
		
=cut
method removeKey ( $section_keypair, $key ) {
	$self->logNote("key, value)");

	my ($section_name, $section_value) = $section_keypair =~ /^([^:]+):?(.*)$/;
	$self->logWarning("section_name not defined") if not defined $section_name;
	$self->logWarning("key not defined") if not defined $key;
	$self->logNote("key, value, comment)");

	$self->logNote("section_name: **$section_name**");
	$self->logNote("section_value", $section_value);
	$self->logNote("key", $key);
	
	#### SANITY CHECK
	$self->logWarning("section_name not defined") if not defined $section_name;
	$self->logWarning("key not defined") if not defined $key;

	#### SEARCH FOR SECTION AND ADD KEY-VALUE PAIR IF FOUND	
	my $sections = $self->read();
	my $matched = 0;
	my $removed_value;
	foreach my $current_section ( @$sections )
	{
		$self->logNote("current_section->{key}: **$current_section->{key}**");
		$self->logNote("current_section->{value}", $current_section->{value});
	
		next if not $current_section->{key} eq $section_name;
		$self->logNote("PASSED WITH KEY", $current_section->{key});

		$matched = 1;
		$self->logNote("matched", $matched);

		$removed_value = $self->_removeKey($current_section, $key);
		$self->logNote("_removeKey SUCCESS", $removed_value);
		return 0 if not $removed_value;
		
		#### REMOVE SECTION IF EMPTY
		if ( $self->_sectionIsEmpty($current_section) )
		{
			$self->logNote("section is empty");
			$self->_removeSection($sections, $current_section);
			$self->logNote("remove section removed_value", $removed_value);
			return 0 if not defined $removed_value;
		}
		last;
	}
	$self->logNote("Can't find section", $section_name) if not $matched;
	$self->logNote("OUT OF LOOP removed value", $removed_value);
	return 0 if not $matched;

	$self->write($sections);
	$self->logNote("Returning removed value", $removed_value);
	return $removed_value;
}

=head2

	SUBROUTINE 		_removeKey
	
	PURPOSE
	
		1. REMOVE A KEY-VALUE PAIR FROM A SECTION
		
=cut
method _removeKey ( $section, $key ) {
	$self->logNote("key)");
	$self->logNote("key", $key);
	
	#### SANITY CHECK
	$self->logWarning("section not defined") if not defined $section;
	$self->logWarning("key not defined") if not defined $key;
	return 0 if not defined $section->{keypairs}->{$key};
	#return 0 if defined $value xor defined $section->{keypairs}->{$key}->{value};
	#return 0 if defined $value and $section->{keypairs}->{$key}->{value} ne $value;
	$self->logNote("section->{keypairs}->{$key}->{value}: ", $section->{keypairs}->{$key}->{value}, "");

	my $value = $section->{keypairs}->{$key}->{value};
	$self->logNote("value", $value);

	delete $section->{keypairs}->{$key};

	$self->logNote("key", $key);
	return $value;
}


method writeToMemory ( $sections ) {
	$self->logDebug("Doing self->sections(sections)");
	$self->sections($sections);
}

method readFromMemory {
	return $self->sections();
}


}