use strict;
use warnings;

use utf8;

use Test::More tests => 337;
use Test::Exception;
use HumanNameParser;


my $name = new HumanNameParser(
	name => 'Björn O\'Malley, Jr.' );

ok($name, 'Object is OK');

note('Test suffix');
is($name->getLastName, 'O\'Malley');
is($name->getFirstName, 'Björn');
is($name->getSuffix, 'Jr.');

note('Test title and suffix');
$name->name('Dr. Björn O\'Malley, Sr.');
is($name->getLastName, 'O\'Malley');
is($name->getFirstName, 'Björn');
is($name->getSuffix, 'Sr.');
is($name->getTitle, 'Dr.');

note('Test "arbitrary complexity and various wacky formats" example 1');
$name->name('J. Walter Weatherman');
is($name->getLastName, 'Weatherman');
is($name->getFirstName, 'Walter');
is($name->getLeadingInitial, 'J.');

note('Test "arbitrary complexity and various wacky formats" example 2');
$name->name('de la Cruz, Ana M.');
is($name->getLastName, 'de la Cruz');
is($name->getFirstName, 'Ana');
is($name->getMiddleName, 'M.');

note('Test "arbitrary complexity and various wacky formats" example 3');
$name->name('James C. (\'Jimmy\') O\'Dell, Jr.');
is($name->getLastName, 'O\'Dell');
is($name->getSuffix, 'Jr.');
is($name->getNickNames, 'Jimmy');
is($name->getFirstName, 'James');
is($name->getMiddleName, 'C.');

note('Test "arbitrary complexity and various wacky formats" example 4');
$name->name('Edwin van der Sar');
is($name->getLastName, 'van der Sar');
is($name->getFirstName, 'Edwin');

note('Test "arbitrary complexity and various wacky formats" example 5');
$name->name('José Ortega y Gasset');
is($name->getLastName, 'Ortega y Gasset');
is($name->getFirstName, 'José');

note('Test UTF-8 name (cyrillic)');
$name->name('Чайковский, Пётр Ильич');
is($name->getLastName, 'Чайковский');
is($name->getFirstName, 'Пётр');
is($name->getMiddleName, 'Ильич');

note('Test UTF-8 name w. nick name (cyrillic)');
$name->name('Пётр (Peter) Ильич Чайковский');
is($name->getLastName, 'Чайковский');
is($name->getFirstName, 'Пётр');
is($name->getMiddleName, 'Ильич');
is($name->getNickNames, 'Peter');

note('Test full UTF-8 upper case name (cyrillic)');
$name->name('ЧАЙКОВСКИЙ, ПИ');
is($name->_nameIsMixedCase, 0);
is($name->getLastName, 'ЧАЙКОВСКИЙ');
is($name->getFirstName, 'ПИ');

note('Test UTF-8 name mixed case (cyrillic)');
$name->name('Чайковский, ПИ');
is($name->_nameIsMixedCase, 1);
is($name->getLastName, 'Чайковский');
is($name->getFirstName, 'П');
is($name->getMiddleName, 'И');

note('Test "russian" name form (cyrillic)');
$name->name('Чайковский ПИ');
is($name->_nameIsMixedCase, 1);
is($name->getLastName, 'Чайковский');
is($name->getFirstName, 'П');
is($name->getMiddleName, 'И');

$name->name('ПИ Чайковский');
is($name->_nameIsMixedCase, 1);
is($name->getLastName, 'Чайковский');
is($name->getFirstName, 'П');
is($name->getMiddleName, 'И');

$name->name('Чайковский, П. И.');
is($name->getLastName, 'Чайковский');
is($name->getFirstName, 'П.');
is($name->getMiddleName, 'И.');

note('Test initial + last name');
$name->name('R. Crumb');
is($name->getLastName, 'Crumb');
is($name->getFirstName, 'R.');

note('Test simple name');
$name = new HumanNameParser(
	name => 'Hans Meiser' );
is($name->getFirstName, 'Hans');
is($name->getLastName, 'Meiser');

note('Test reverse name');
$name = new HumanNameParser(
	name => 'Meiser, Hans' );
is($name->getFirstName, 'Hans');
is($name->getLastName, 'Meiser');

note('Test reverse nane w. slash');
$name = new HumanNameParser(
	name => 'Smith / Joe' );
is($name->getFirstName, 'Joe');
is($name->getLastName, 'Smith');

note('Test reverse w. academic title');
$name = new HumanNameParser(
	name => 'Dr. Meiser, Hans' );
is($name->getTitle, 'Dr.');
is($name->getFirstName, 'Hans');
is($name->getLastName, 'Meiser');

note('Test straight w. academic title');
$name = new HumanNameParser(
	name => 'Dr. Hans Meiser' );
is($name->getTitle, 'Dr.');
is($name->getFirstName, 'Hans');
is($name->getLastName, 'Meiser');

note('Test last name w. prefix');
$name = new HumanNameParser(
	name => 'Björn van Olst' );
is($name->getLastName, 'van Olst');
is($name->getFirstName, 'Björn');

note('Test no first name - but mandatory');
sub test1 {
	$name = new HumanNameParser(
		name => 'Mr. Hyde', mandatoryFirstName => 1 );
}
dies_ok { test1(); } 'Test should die here...';

note('Test no last name - but mandatory');
sub test2 {
	my $name = new HumanNameParser(
		name => 'Edward', mandatoryLastName => 1 );
}
dies_ok { test2(); } 'Test should die here...';

note('Test no first name - but not mandatory');
sub test3 {
	$name = new HumanNameParser(
		name => 'Dr. Jekyll', mandatoryFirstName => 0 );
}
lives_ok { test3(); } 'Test should not die here...';
is($name->getTitle, 'Dr.');
is($name->getLastName, 'Jekyll');

note('Test no last name - but not mandatory');
sub test4 {
	$name = new HumanNameParser(
		name => 'Henry', mandatoryLastName => 0 );
}
lives_ok { test4(); } 'Test should not die here...';
is($name->getFirstName, 'Henry');

my @test_array = (
	'Björn O\'Malley;;Björn;;;O\'Malley;',
	'Bin Lin;;Bin;;;Lin;',
	'Linda Jones;;Linda;;;Jones;',
	'Jason H. Priem;;Jason;;H.;Priem;',
	'Björn O\'Malley-Muñoz;;Björn;;;O\'Malley-Muñoz;',
	'Björn C. O\'Malley;;Björn;;C.;O\'Malley;',
	'Björn "Bill" O\'Malley;;Björn;Bill;;O\'Malley;',
	'Björn ("Bill") O\'Malley;;Björn;Bill;;O\'Malley;',
	'Björn ("Wild Bill") O\'Malley;;Björn;Wild Bill;;O\'Malley;',
	'Björn (Bill) O\'Malley;;Björn;Bill;;O\'Malley;',
	'Björn \'Bill\' O\'Malley;;Björn;Bill;;O\'Malley;',
	'Björn C O\'Malley;;Björn;;C;O\'Malley;',
	'Björn C. R. O\'Malley;;Björn;;C. R.;O\'Malley;',
	'Björn Charles O\'Malley;;Björn;;Charles;O\'Malley;',
	'Björn Charles R. O\'Malley;;Björn;;Charles R.;O\'Malley;',
	'Björn van O\'Malley;;Björn;;;van O\'Malley;',
	'Björn Charles van der O\'Malley;;Björn;;Charles;van der O\'Malley;',
	'Björn Charles O\'Malley y Muñoz;;Björn;;Charles;O\'Malley y Muñoz;',
	'Björn O\'Malley, Jr.;;Björn;;;O\'Malley;Jr.;',
	'Björn O\'Malley Jr;;Björn;;;O\'Malley;Jr;',
	'B O\'Malley;;B;;;O\'Malley;',
	'William Carlos Williams;;William;;Carlos;Williams;',
	'C. Björn Roger O\'Malley;C.;Björn;;Roger;O\'Malley;',
	'B. C. O\'Malley;;B.;;C.;O\'Malley;',
	'B C O\'Malley;;B;;C;O\'Malley;',
	'B.J. Thomas;;B.J.;;;Thomas;',
	'O\'Malley, Björn;;Björn;;;O\'Malley;',
	'O\'Malley, Björn Jr;;Björn;;;O\'Malley;Jr',
	'O\'Malley, C. Björn;C.;Björn;;;O\'Malley;',
	'O\'Malley, C. Björn III;C.;Björn;;;O\'Malley;III',
	'O\'Malley y Muñoz, C. Björn Roger III;C.;Björn;;Roger;O\'Malley y Muñoz;III',
	'O\'Malley / C. Björn;C.;Björn;;;O\'Malley;',
	'Smith / Joe;;Joe;;;Smith;',
	'Smith/ Ms Jane Middle;;Jane;;Middle;Smith;;Ms',
	'Smith Jr / Dr Joe;;Joe;;;Smith;Jr;Dr',
	'Dr. John Smith;;John;;;Smith;;Dr.',
	'John Smith, PhD;;John;;;Smith;;PhD',
	'John Smith Bsc;;John;;;Smith;;Bsc',
	#'Dr. John Smith, PhD;;John;;;Smith;;PhD',
	);


{
	no warnings qw(uninitialized);

	my $name = new HumanNameParser();

	foreach my $test_line (@test_array) {
		my @nameparts = split(/;/, $test_line);
		note('Testing name: ' . $nameparts[0]);

		$name->name($nameparts[0]);

		is($name->getLeadingInitial, $nameparts[1] ne "" ? $nameparts[1] : undef, sprintf("Check expected leading initial (%s) in name %s", $nameparts[1], $name->name));
		is($name->getFirstName, $nameparts[2] ne "" ? $nameparts[2] : undef, sprintf("Check expected first name (%s) in name %s", $nameparts[2], $name->name));
		is($name->getNickNames, $nameparts[3] ne "" ? $nameparts[3] : undef, sprintf("Check expected nickname (%s) in name %s", $nameparts[3], $name->name));
		is($name->getMiddleName, $nameparts[4] ne "" ? $nameparts[4] : undef, sprintf("Check expected middle name (%s) in name %s", $nameparts[4], $name->name));
		is($name->getLastName, $nameparts[5] ne "" ? $nameparts[5] : undef, sprintf("Check expected last name (%s) in name %s", $nameparts[5], $name->name));
		is($name->getSuffix, $nameparts[6] ne "" ? $nameparts[6] : undef, sprintf("Check expected suffix (%s) in name %s", $nameparts[6], $name->name));
		is($name->getTitle, $nameparts[7] ne "" ? $nameparts[7] : undef, sprintf("Check expected title (%s) in name %s", $nameparts[7], $name->name));
	}
}

#done_testing;
