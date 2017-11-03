#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

my @found;

package MyTidy;

use MooX qw/ late /;
use IO::All qw/ io /;
extends('Test::HTML::Tidy::Recursive');

sub check_file
{
    my ( $self, $args ) = @_;

    my $fn = $args->{filename};

    my $fh = io->file($fn);

    push @found, +{
        bn    => $fh->filename,
        title => do { my @f = $fh->utf8->all =~ m#<h1>(.*?)</h1>#ms; $f[0] }
    };

    return;
}

package main;

{
    my $obj = MyTidy->new( { targets => ["t/data/sample-sites/1/"] } );
    $obj->traverse;

    # TEST
    is_deeply(
        \@found,
        [
            { bn => 'about.html', title => "About_title" },
            { bn => 'index.html', title => 'Foo.' },
        ],
        "Right results."
    );
}

