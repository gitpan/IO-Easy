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

$io->dir_io ('x')->create;
$io->file_io ('x', 'y')->touch;
$io->dir_io ('z')->create;

my @scanned;

$io->scan_tree (sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
	return 0 if $f->name eq 'x';
});

ok join (', ', sort @scanned) eq 'b, x, z', join (', ', sort @scanned);

@scanned = ();

$io->scan_tree (sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
});

ok join (', ', sort @scanned) eq 'b, x, x/y, z', join (', ', sort @scanned);

@scanned = ();

$io->scan_tree (for_files_only => sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
});

ok join (', ', sort @scanned) eq 'b, x/y', join (', ', sort @scanned);

@scanned = ();

$io->scan_tree (ignoring_return => sub {
	my $f = shift;
	push @scanned, $f->rel_path ($io);
	return 0 if $f->name eq 'x';
});

ok join (', ', sort @scanned) eq 'b, x, x/y, z', join (', ', sort @scanned);


my @files = $io->items;

ok $file->path eq $files[0]->path;

$io->rm_tree;
