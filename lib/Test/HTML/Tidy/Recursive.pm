package Test::HTML::Tidy::Recursive;

use strict;
use warnings;
use 5.008;

our $VERSION = 'v0.0.3';

use Test::More;

use HTML::Tidy;
use File::Find::Object::Rule;
use IO::All qw/ io /;

use MooX qw/ late /;

has filename_re => (is => 'ro', default => sub {
        return qr/\.x?html\z/;
    });

has targets => (is => 'ro', isa => 'ArrayRef', required => 1);

has filename_filter => (is => 'ro', default => sub { return sub { return 1; } });

has _tidy => (is => 'rw');

sub calc_tidy
{
    my $self = shift;

    my $tidy = HTML::Tidy->new({ output_xhtml => 1, });
    $tidy->ignore( type => TIDY_WARNING, type => TIDY_INFO );

    return $tidy;
}

sub run
{
    my $self = shift;
    plan tests => 1;
    local $SIG{__WARN__} = sub {
        my $w = shift;
        if ($w !~ /\AUse of uninitialized/)
        {
            die $w;
        }
        return;
    };

    $self->_tidy($self->calc_tidy);

    my $error_count = 0;

    my $filename_re = $self->filename_re;
    my $filter = $self->filename_filter;

    foreach my $target (@{$self->targets})
    {
        for my $fn (File::Find::Object::Rule->file()->name($filename_re)->in($target))
        {
            if ($filter->($fn))
            {
                $self->_tidy->parse( $fn, (scalar io->file($fn)->slurp()));

                for my $message ( $self->_tidy->messages ) {
                    $error_count++;
                    diag( $message->as_string);
                }

                $self->_tidy->clear_messages();
            }
        }
    }

    $self->_tidy('NULL');

    # TEST
    is ($error_count, 0, "No errors");
}

1;

__END__

=head1 NAME

Test::HTML::Tidy::Recursive - recursively check files in a directory using
HTML::Tidy .

=head1 SYNOPSIS

    use Test::HTML::Tidy::Recursive;

    Test::HTML::Tidy::Recursive->new({
        targets => ['./dest-html', './dest-html-production'],
        })->run;

Or with over-riding the defaults:

    use Test::HTML::Tidy::Recursive;

    Test::HTML::Tidy::Recursive->new({
        filename_re => qr/\.x?html?\z/i,
        filename_filter => sub { return shift !~ m#MathJax#; },
        targets => ['./dest-html', './dest-html-production'],
        })->run;

=head1 DESCRIPTION

This module acts as test module which runs L<HTML::Tidy> on some directory
trees containing HTML/XHTML files and checks that they are all valid.

It was extracted from a bunch of nearly duplicate test scripts in some of
my (= Shlomi Fish) web sites, as an attempt to avoid duplicate code and
functionality.

=head1 METHODS

=head2 calc_tidy

Calculates the L<HTML::Tidy> object - can be overriden.

=head2 filename_filter

A parameter with a callback to filter the files. Defaults to accept all files.

=head2 filename_re

A regex for which filenames are checked. Defaults to files ending in ".html"
or ".xhtml".

=head2 run

The method that runs the program.

=head2 targets

A parameter that accepts an array reference of targets as strings.

=head1 SEE ALSO

L<HTML::Tidy> .

=cut
