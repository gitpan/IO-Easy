#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

`rm -rf t/a`;

my $path = 't/a';

my $io = IO::Easy->new ($path)->as_dir;

ok (! -e $io);

$io->create;

ok (-d $io);

my $file = $io->append ('b')->as_file;

$file->touch;

foreach (qw(inode atime mtime)) {
	ok $file->$_, "file $_ is: " . $file->$_;
}

foreach (qw(size)) {
	ok ! $file->$_;
}

`rm -rf t/a`;