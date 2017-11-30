package Test::HTML::Tidy::Recursive::Strict;

use MooX qw/ late /;

extends('Test::HTML::Tidy::Recursive');

sub calc_tidy
{
    my $self = shift;

    return HTML::Tidy->new( { output_xhtml => 1, } );
}

1;

__END__

=head1 NAME

Test::HTML::Tidy::Recursive::Strict - recursively check files in a directory
using HTML::Tidy while not ignoring warnings.

=head1 SYNOPSIS

    use Test::HTML::Tidy::Recursive::Strict;

    Test::HTML::Tidy::Recursive::Strict->new({
        targets => ['./dest-html', './dest-html-production'],
        })->run;

=head1 DESCRIPTION

This is a subclass of L<Test::HTML::Tidy::Recursive> that uses a stricter
configuration of L<HTML::Tidy> with no warnings ignored. Refer to the
L<Test::HTML::Tidy::Recursive> documentation for more usage information.

=head1 METHODS

=head2 calc_tidy

Calculates the L<HTML::Tidy> object.

=head1 SEE ALSO

L<HTML::Tidy> , L<Test::HTML::Tidy::Recursive> .

=cut
