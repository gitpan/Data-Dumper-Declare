package Data::Dumper::Declare;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$Data::Dumper::Declare::AUTHORITY = 'cpan:TOBYINK';
	$Data::Dumper::Declare::VERSION   = '0.001';
}

use Carp;
use Data::Dumper;
use Devel::Declare          0.006007    ();
use Devel::Declare::Context::Simple   0 ();
use B::Hooks::EndOfScope    0.09;
use Sub::Install            0.925       qw(install_sub);

sub scalarify (_)
{
	my $_ = shift;
	if    (/^[\$\\]/)      { return $_ }
	elsif (/^[\@\%\&\*]/)  { return "\\$_" }
	else                   { return "scalar($_)" }
}

sub displayify (_)
{
	my $_ = shift;
	if    (/^[\$\\]/)      { return $_ }
	elsif (/^[\@\%\&\*]/)  { return "\\$_" }
	else                   { return "\$EXPR" }
}

use namespace::clean        0.19;

use Sub::Exporter -setup =>
{
	installer  => \&install,
	exports    => [
		Dumper      => sub { \&_callback_Dumper },
		WWW         => sub { \&_callback_WWW },
		XXX         => sub { \&_callback_XXX },
		YYY         => sub { \&_callback_YYY },
		ZZZ         => sub { \&_callback_ZZZ },
	],
	groups     => {
		default => [qw(Dumper)],
		xxx     => [qw(WWW XXX YYY ZZZ)],
	},
};

sub install
{
	my ($args, $to_export) = @_;
	my $target = $args->{into} or die;
	
	my @names;
	while (@$to_export)
	{
		my $name    = shift @$to_export;
		my $coderef = shift @$to_export;
		
		Devel::Declare->setup_for(
			$target => {
				$name => {
					const => sub {
						return __PACKAGE__->_transform($name, @_);
					},
				},
			},
		);
		
		install_sub {
			into => $target,
			as   => $name,
			code => $coderef,
		};
		
		push @names, $name;
	}
	
	on_scope_end {
		namespace::clean->clean_subroutines($target, @names);
	}
}

sub _callback_Dumper
{
	my ($values, $names) = @_;
	local $Data::Dumper::Terse = 1;
	my @return;
	foreach my $i (0 .. $#$values)
	{
		my $name = $names->[$i];
		my $dump = Data::Dumper::Dumper($values->[$i]);
		chomp $dump;
		
		if ($name =~ m{^\\\@\w+$})
		{
			$name = substr($name, 1);
			if ($dump =~ m{^\[(.+)\]$}s)
			{
				$dump = "($1)";
			}
			else
			{
				$dump = "\@{$dump}";
			}
		}
		elsif ($name =~ m{^\\\%\w+$})
		{
			$name = substr($name, 1);
			if ($dump =~ m{^\{(.+)\}$}s)
			{
				$dump = "($1)";
			}
			else
			{
				$dump = "\%{$dump}";
			}
		}
		
		push @return, sprintf("%s = %s;\n", $name, $dump);
	}
	
	wantarray ? @return : join(q() => @return);
}

sub _callback_WWW
{
	my $values = $_[0];
	carp _callback_Dumper(@_);
	wantarray ? @$values : $values->[0];
}

sub _callback_XXX
{
	my $values = $_[0];
	croak _callback_Dumper(@_);
}

sub _callback_YYY
{
	my $values = $_[0];
	print _callback_Dumper(@_);
	wantarray ? @$values : $values->[0];
}

sub _callback_ZZZ
{
	my $values = $_[0];
	confess _callback_Dumper(@_);
}

sub _transform
{
	my $class = shift;
	my $name  = shift;

	my $parser = Data::Dumper::Declare::Parser->new($_[1]);
	return if $parser->get_word ne $name;
	
	$parser->skip_word();
	$parser->skip_spaces();
	
	if ($parser->get_symbols(1) ne '(')
	{
		croak "You must only use $name as '$name(expression)', failed";
	}
	
	my @list = $parser->get_arg_list;
	
	my @real_args    = map { scalarify } @list;
	my @display_args = map { displayify } @list;
	
	my $real_args    = join ',', @real_args;
	my $display_args = join ',', map { qq(q($_)) } @display_args;
	
	$parser->inject("([$real_args], [$display_args])");
}

{
	package Data::Dumper::Declare::Parser;
	use base qw[Devel::Assert::Parser];

	use PPI;
	use PPI::Dumper;

	sub get_arg_list
	{
		my $parser = shift;
		
		my $args  = $parser->extract_args;
		my $doc   = PPI::Document->new(\$args)
			or Carp::croak("could not parse argument list");
		my $list  = $doc->find_first('Statement')
			or return;
		
		my @items;
		my $pos = 0;
		foreach my $child ($list->children)
		{
			next if $child->isa('PPI::Token::Whitespace');
			next if $child->isa('PPI::Token::Comment');
						
			if ("$child" eq ",")
			{
				++$pos;
				next;
			}
			
			$items[$pos] .= $child;
		}
		
		return @items;
	}
}

__PACKAGE__
__END__

=head1 NAME

Data::Dumper::Declare - Data::Dumper, sweetened with Devel::Declare

=head1 SYNOPSIS

  use Data::Dumper::Declare;
  print Dumper($account_data);

=head1 DESCRIPTION

This module provides a C<Dumper> function much the same as the
L<Data::Dumper> C<Dumper> function, but thanks to a bit of
L<Devel::Declare> magic, it knows the variable names passed to it,
so rather than printing something like:

  $VAR1 = {
    balance => 42.00
  };

It will print:

  $account_data = {
    balance => 42.00
  };

It can be passed arrays and hashes directly, with no need to create
a reference to them...

  my @foo = qw(1 2 3);
  print Dumper(@foo);

will print...

  @foo = (
    1,
    2,
    3
  );

This module is nowhere near as stable, mature and well-understoof as
Data::Dumper; but on the other hand, as it's mostly for use in debugging
code, and not production code, it's probably stable enough.

=head2 XXX Comptability

This module also offers an L<XXX> workalike mode, supporting C<WWW>,
C<XXX>, C<YYY> and C<ZZZ> functions.

  use Data::Dumper::Declare -xxx;
  
  sub greeting {
    my $greeting = 'Hello';
    return WWW($greeting); # prints warning
  }
  
  my $bar = greeting(); # $bar is now "Hello"

=head2 Exports

Exports only C<Dumper> by default. This module uses L<Sub::Exporter>
allowing you to rename functions quite easily:

  use Data::Dumper::Declare
    Dumper  => { -as => 'DUMP' };

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Data-Dumper-Declare>.

=head1 SEE ALSO

L<Data::Dumper>, L<XXX>, L<Devel::Assert>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

