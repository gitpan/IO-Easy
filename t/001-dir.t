#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

my $path = 't/a';

my $t = IO::Easy->new ('t');

my $io  = $t->append ('a')->as_dir;
my $io2 = $t->dir_io ('a');

ok $io eq $io2;

$io->rm_tree
	if -d $io;

ok (! -e $io);

$io->create;

ok (-d $io);

my $file = $io->append ('b')->as_file;

my $file2 = $io->file_io ('b');

ok $file eq $file2;

$file->touch;

my @files = $io->items;

ok $file->path eq $files[0]->path;

$io->rm_tree;
