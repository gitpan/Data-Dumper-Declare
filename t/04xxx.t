use Test::More tests => 3;
use Test::Warn;
use Test::Exception;
use Data::Dumper::Declare -xxx;

my $foo = 1;
my $bar;
warnings_like { $bar = WWW($foo) }
           qr { \$foo\s=\s1 }x;

is($bar, $foo);

throws_ok     { $bar = XXX($foo) }
           qr { \$foo\s=\s1 }x;
