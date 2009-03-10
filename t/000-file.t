#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
};

my $path = 'test_file_gtwbwerwerf';

unlink $path;

my $io = IO::Easy->new ($path);

ok (! -e $io);

my $file = $io->as_file;

$io->touch;

ok (-e $io, "file name is: '$io'");
ok (-e $io->abs_path, "abs file name is: '".$io->abs_path."'");

ok (ref $io eq qw(IO::Easy::File), "package changed: " . ref $io);

ok ($io->layer eq ':raw', "layer is: " . $io->layer);

$io->enc ('utf-8');

ok ($io->layer eq ':encoding(utf-8)');

my $string_raw = 'чочо!';

my $string = Encode::decode_utf8 ($string_raw);
ok Encode::is_utf8 ($string);

$io->store ($string);

my $string2 = $io->contents;
ok Encode::is_utf8 ($string2);

ok ($string2 eq $string, "string length: " . length ($string2));

diag $string2;

$io->store ($string_raw);

diag $io->enc;
diag $io->layer;

$string2 = $io->contents;

TODO: { # 
	local $TODO = 'FCUK!!!';
	
	ok ($string2 eq $string, "string length: " . length ($string2));
}

diag $string2;

# ok unlink $path;

