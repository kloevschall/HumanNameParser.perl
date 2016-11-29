requires 'Method::Signatures';
requires 'Moo';
requires 'Types::Standard';
requires 'strictures';
requires 'namespace::clean';

on 'test' => sub {
	requires 'Test::More';
	requires 'Test::Exception';
};

