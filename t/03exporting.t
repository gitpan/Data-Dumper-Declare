use Test::More tests => 1;
use Data::Dumper::Declare Dumper => { -as => 'DUMP' };

my $foo = 1;

is(
	DUMP($foo),
	"\$foo = 1;\n",
);

