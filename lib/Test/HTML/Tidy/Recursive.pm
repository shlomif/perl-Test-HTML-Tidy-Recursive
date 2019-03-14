package Test::HTML::Tidy::Recursive;

use strict;
use warnings;
use 5.008;

use Test::More;

use HTML::T5;
use File::Find::Object::Rule ();
use IO::All qw/ io /;

use MooX qw/ late /;

has filename_re => (
    is      => 'ro',
    default => sub {
        return qr/\.x?html\z/;
    }
);

has targets => ( is => 'ro', isa => 'ArrayRef', required => 1 );

has filename_filter => (
    is      => 'ro',
    default => sub {
        return sub { return 1; }
    }
);

has _tidy        => ( is => 'rw' );
has _error_count => ( is => 'rw', isa => 'Int', default => 0 );

sub report_error
{
    my ( $self, $args ) = @_;

    $self->_error_count( 1 + $self->_error_count );
    diag( $args->{message} );

    return;
}

sub calc_tidy
{
    my $self = shift;

    my $tidy = HTML::T5->new( { output_xhtml => 1, } );
    $tidy->ignore( type => TIDY_WARNING, type => TIDY_INFO );

    return $tidy;
}

sub run
{
    my $self = shift;
    plan tests => 1;
    local $SIG{__WARN__} = sub {
        my $w = shift;
        if ( $w !~ /\AUse of uninitialized/ )
        {
            die $w;
        }
        return;
    };

    $self->_tidy( $self->calc_tidy );
    $self->traverse;
    $self->_tidy('NULL');

    # TEST
    return is( $self->_error_count, 0, "No errors" );
}

sub check_using_tidy
{
    my ( $self, $args ) = @_;

    my $fn = $args->{filename};

    $self->_tidy->parse( $fn, ( scalar io->file($fn)->slurp() ) );

    for my $message ( $self->_tidy->messages )
    {
        $self->report_error(
            {
                message => scalar $message->as_string
            }
        );
    }

    $self->_tidy->clear_messages();

    return;
}

sub check_file
{
    my ( $self, $args ) = @_;

    $self->check_using_tidy($args);

    return;
}

sub traverse
{
    my ($self) = @_;
    $self->_error_count(0);
    my $filename_re = $self->filename_re;
    my $filter      = $self->filename_filter;

    foreach my $target ( @{ $self->targets } )
    {
        for my $fn (
            File::Find::Object::Rule->file()->name($filename_re)->in($target) )
        {
            if ( $filter->($fn) )
            {
                $self->check_file( { filename => $fn } );
            }
        }
    }

    return;
}

1;

__END__

=head1 NAME

Test::HTML::Tidy::Recursive - recursively check files in a directory using
HTML::T5 .

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

This module acts as test module which runs L<HTML::T5> on some directory
trees containing HTML/XHTML files and checks that they are all valid.

It was extracted from a bunch of nearly duplicate test scripts in some of
my (= Shlomi Fish) web sites, as an attempt to avoid duplicate code and
functionality.

=head1 METHODS

=head2 calc_tidy

Calculates the L<HTML::T5> object - can be overriden.

=head2 filename_filter

A parameter with a callback to filter the files. Defaults to accept all files.

=head2 filename_re

A regex for which filenames are checked. Defaults to files ending in ".html"
or ".xhtml".

=head2 run

The method that runs the program.

=head2 $obj->check_file({filename => $path_string})

Override this method in subclasses to check a file in a different way.

=head2 $obj->check_using_tidy({filename => $path_string})

Actually check a file using tidy. Used by check_file() by default,
but can also be called there in subclasses.

=head2 $obj->report_error({message => $string});

Reports the error and increment the error count.

=head2 $obj->traverse()

The method that gets called by run() to do the actual traversal of the tree
without actually checking for no errors. Useful for testing and debugging.

=head2 targets

A parameter that accepts an array reference of targets as strings.

=head1 SEE ALSO

L<HTML::T5> .

=cut
