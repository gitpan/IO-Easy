#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

`rm -rf t/a`; # not non-unix compliant

my $path = 't/a';

my $io = IO::Easy->new ($path)->as_dir;

ok (! -e $io);

$io->create;

ok (-d $io);

my $file = $io->append ('b')->as_file;

$file->touch;

my @files = $io->items;

ok $file->path eq $files[0]->path;


