package HumanNameParser;

use utf8;

use Method::Signatures;
use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw/Bool Str Maybe Ref/;
use warnings::register;
use version;

our $VERSION = version->declare("v0.1.0");

has name => (
	is => 'rw',
	isa => Maybe[Str],
	trigger => 1,
	);

has suffixes => (
	is => 'rw',
	lazy => 1,
	isa => Ref['ARRAY'],
	default => sub { ['esq','esquire','jr','sr','2','ii','iii','iv'] }
	);

has prefixes => (
	is => 'rw',
	lazy => 1,
	isa => Ref['ARRAY'],
	default => sub { ['bar','ben','bin','da','dal','de la','de','del',
	'der','di','ibn','la','le','san','st','ste','van','van der','van den','vel','von'] }
	);

has titles => (
	is => 'rw',
	lazy => 1,
	isa => Ref['ARRAY'],
	default => sub { ['ms','miss','mrs','mr','prof','dr','ph\.?[ ]?d','(m|b)\.?[ ]?sc','md'] }
	);

has mandatoryFirstName => (
	is => 'rw',
	isa => Bool,
	default => 0
	);

has mandatoryLastName => (
	is => 'rw',
	isa => Bool,
	default => 0
	);

has _nameIsMixedCase => (
	is => 'rw',
	isa => Bool
	);

has _nameToken => (
	is => 'rw',
	isa => Maybe[Str]
	);

has getTitle => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setTitle'
	);

has getSuffix => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setSuffix'
	);

has getLastName => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setLastName'
	);

has getFirstName => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setFirstName'
	);

has getLeadingInitial => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setLeadingInitial'
	);

has getNickNames => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setNickNames'
	);

has getMiddleName => (
	is => 'ro',
	isa => Maybe[Str],
	writer => 'setMiddleName'
	);


my $REGEX_NICKNAMES       = '\s((?:\'|"|\("*\'*).+?(?:\'|"|"*\'*\)))\s';
my $REGEX_TITLES1         = '^(%s)\.*';
my $REGEX_TITLES2         = ',?\s(%s)$';
my $REGEX_SUFFIX          = ',*\s*(%s)$';
my $REGEX_LAST_NAME       = '(?!^)\b(([^\s]+\sy\s|%s)*[^\s]+)$';
my $REGEX_LEADING_INITIAL = '^(.\.*)(?=\s\p{L}{2})';
my $REGEX_FIRST_NAME      = '^[^\s]+';


method _trigger_name($name) {
	# Reset object on trigger
	$self->setTitle(undef);
	$self->setSuffix(undef);
	$self->setLastName(undef);
	$self->setFirstName(undef);
	$self->setLeadingInitial(undef);
	$self->setNickNames(undef);
	$self->setMiddleName(undef);

	$self->parse();
}

# Human name parser
method parse {
	# Each suffix gets a "\.*" behind it.
	my $suffixes = join("\\.*|", @{$self->suffixes}) . "\\.*"; 

	# Each prefix gets a " " behind it.
	my $prefixes = join(" |", @{$self->prefixes}) . " ";

	# Each title gets a "\.*" behind it.
	my $titles = join("\\.*|", @{$self->titles}) . "\\.*";

	# Check if the string is all upper or lower case
	if ( ($self->name eq uc $self->name) or ($self->name eq lc $self->name) ) {
		$self->_nameIsMixedCase(0);
	}
	# Or mixed case...
	else {
		$self->_nameIsMixedCase(1);
	}


	$self->_nameToken($self->name);

	# Flip on slashes before any other transformation
	$self->_nameToken(_flipNameToken("/", $self->_nameToken));

	$self->_findTitle($titles);
	$self->_findNicknames();

	$self->_findSuffix($suffixes);

	# Flip on commas
	$self->_nameToken(_flipNameToken(",", $self->_nameToken));

	# Separate concatinated initials from last name (LastName INI -> INI LastName)
	if ( $self->_nameIsMixedCase ) {
		my $string = $self->_nameToken;
		$string =~ s/^(.*?) (\p{Uppercase}{2,})$/$2 $1/g;
		$self->_nameToken($string);
	}

	# Separate concatenated initials (INI Last name -> I N I Last name)
	if ( $self->_nameIsMixedCase ) {
		my $string = $self->_nameToken;
		$string =~ s/(\p{Uppercase})(?=\p{Uppercase})/$1 /g;
		$self->_nameToken($string);
	}

	# Find name parts
	$self->_findLastName($prefixes);
	$self->_findLeadingInitial();
	$self->_findFirstName();
	$self->_findMiddleName();

	# Fix for construction: "Title LastName", where FirstName becomes LastName
	if ( ! $self->getLastName and ( $self->getTitle and $self->getFirstName) ) {
		if ( $self->mandatoryFirstName ) {
			die "Couldn't find a first name.";
		}
		$self->setLastName($self->getFirstName);
		$self->setFirstName(undef);
	}
}

# Helpers
func _flipNameToken($pattern, $name) {
	my @substrings = split(/$pattern/, $name);

	if ( scalar @substrings == 2 ) {
		$name  = _normalize($substrings[1] . " " . $substrings[0]);
	}
	elsif ( scalar @substrings > 2 ) {
		warnings::warn "Can't flip around multible '$pattern' characters in namestring" if warnings::enabled();
	}

	return $name;
}

method _findTitle($titles) {
	# Try first method to extract a title
	my $regex = sprintf($REGEX_TITLES1, $titles);

	my $title = _findWithRegex(_normalize($self->_nameToken), $regex);

	# Remove title from name
	if ( $title ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $title), length($title)) = "";
		$self->_nameToken($name);
		$self->setTitle($title);
		return;
	}

	# Try second method to extract a title
	$regex = sprintf($REGEX_TITLES2, $titles);

	$title = _findWithRegex(_normalize($self->_nameToken), $regex);

	# Remove title from name
	if ( $title ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $title), length($title)) = "";
		$self->_nameToken($name);
		$self->setTitle($title);
		return;
	}

}

method _findSuffix($suffixes) {
	my $regex = sprintf($REGEX_SUFFIX, $suffixes);

	my $suffix = _findWithRegex(_normalize($self->_nameToken), $regex);

	if ( $suffix ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $suffix), length($suffix)) = "";
		$self->_nameToken($name);
		$self->setSuffix($suffix);		
	}
}

func _findWithRegex($string, $regex) {
	my @m = ($string =~ m{$regex}gui);

	return $m[0] if $m[0];
}

method _findNicknames {
	my $nicknames = _findWithRegex(_normalize($self->_nameToken), $REGEX_NICKNAMES);

	if ( $nicknames ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $nicknames), length($nicknames)) = "";

		# Trim the nickname down to the name part
		$nicknames =~ s{^('|\"|\(\"*'*)}{};
		$nicknames =~ s{('|\"|\"*'*\))$}{};

		$self->_nameToken($name);
		$self->setNickNames($nicknames);
	}
}

method _findLastName($prefixes) {
	my $regex = sprintf($REGEX_LAST_NAME, $prefixes);

	my $lastName = _findWithRegex(_normalize($self->_nameToken), $regex);

	if ( $lastName ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $lastName), length($lastName)) = "";
		$self->_nameToken($name);
		$self->setLastName($lastName);
	}
	elsif ( $self->mandatoryLastName ) {
		die "Couldn't find a last name.";
	}
}

method _findLeadingInitial {
	my $leadingInitial = _findWithRegex(_normalize($self->_nameToken), $REGEX_LEADING_INITIAL);

	if ( $leadingInitial ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $leadingInitial), length($leadingInitial)) = "";
		$self->_nameToken($name);
		$self->setLeadingInitial($leadingInitial);
	}
}

method _findFirstName {
	my $firstName = _findWithRegex(_normalize($self->_nameToken), $REGEX_FIRST_NAME);

	if ( $firstName ) {
		my $name = $self->_nameToken;
		substr($name, index($name, $firstName), length($firstName)) = "";
		$self->_nameToken($name);
		$self->setFirstName($firstName);
	}
	elsif ( $self->mandatoryFirstName ) {
		die "Couldn't find a first name.";
	}
}

method _findMiddleName {
	my $middleName = _trim($self->_nameToken);
	
	if ( $middleName ) {
		$self->setMiddleName($middleName);
	}
}

# Removes extra whitespace and punctuation from string
# Strips whitespace chars from ends, strips redundant whitespace, converts whitespace chars to " ".
func _normalize($string) {
	$string =~ s{^\s*}{}u;
	$string =~ s{\s*$}{}u;
	$string =~ s{\s+}{ }u;
	$string =~ s{,$}{ }u;

	return $string;
}

# Trim extra whitespace from beginning and end of string
# http://php.net/manual/en/function.trim.php
func _trim($string) {
	if ( $string ) {
		$string =~ s{^(\s|\t|\n|\r|\0|\x0B)+}{}s;
		$string =~ s{(\s|\t|\n|\r|\0|\x0B)+$}{}s;
	}

	return $string;
}

1;
