use 5.010;
use lib "lib";
use lib "../lib";
use Data::Dumper::Declare Dumper => { -as => 'DUMP' };

my $foo = 1;
my $bar = [qw(2 3 4)];
my @baz = qw(5 6 7);

print DUMP(
	$foo,
	$bar,
	substr($foo, 0, 1),
	@baz,
);
