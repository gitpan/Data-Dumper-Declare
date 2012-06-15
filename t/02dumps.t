use Test::More tests => 10;
use Data::Dumper::Declare;

$Data::Dumper::Indent = 0;

my $scalar = 'Hello World';
my @array  = qw(Hello World);
my %hash   = qw(Hello World);

sub line ($)
{
	shift . "\n";
}

is(
	Dumper($scalar),
	line q<$scalar = 'Hello World';>,
	'scalars',
);

is(
	Dumper(@array),
	line q<@array = ('Hello','World');>,
	'arrays',
);

is(
	Dumper(%hash),
	line q<%hash = ('Hello' =\> 'World');>,
	'hashes',
);

is(
	Dumper(\@array),
	line q<@array = ('Hello','World');>,
	'array with explicit ref',
);

is(
	Dumper(\%hash),
	line q<%hash = ('Hello' =\> 'World');>,
	'hash with explicit ref',
);

is(
	Dumper( [qw(Hello World)] ),
	line q<$EXPR = ['Hello','World'];>,
	'anonymous array',
);

is(
	Dumper( {Hello => 'World'} ),
	line q<$EXPR = {'Hello' =\> 'World'};>,
	'anonymous hash',
);

is(
	Dumper(substr($scalar, 0, 5)),
	line q<$EXPR = 'Hello';>,
	'function call',
);

is(
	Dumper(substr($scalar, 0, 5), substr($scalar, 6, 5)),
	line(q<$EXPR = 'Hello';>).line(q<$EXPR = 'World';>),
	'multiple arguments',
);

is(
	Dumper(),
	'',
	'empty list',
);