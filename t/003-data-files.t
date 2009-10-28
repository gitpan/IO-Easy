#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

my $files = IO::Easy::File->__data__files;

ok scalar keys %$files == 3;

my $hello = $files->{hello};

ok $hello =~ /^# comment here/s;

my @hello_chunks = split /\n/, $hello; # to avoid stupid warnings

ok scalar (@hello_chunks) == 5;

my $bye = $files->{bye};

ok $bye =~ /# comment here/s;

$files = IO::Easy::File->__data__files;

ok scalar keys %$files == 3;

__DATA__

##################################
# IO::Easy hello
##################################

# comment here

{
	[hello!!!]
}

##################################
# IO::Easy hello2
##################################

# comment here

{
	[hello!!!]
}

##################################
IO::Easy bye
##################################

{
	# comment here
	bye!!!
}
