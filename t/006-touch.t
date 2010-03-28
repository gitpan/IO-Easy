#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

#-----------------------------------------------
sub create_file
{
	die "usage" unless @_;
	
	die "can't open $_[0]: $!\n"
		unless open(TF, '>', $_[0]);
	
	print TF @_[1..$#_];
	close TF;
}

sub unlink_file
{
	die "can't delete $_[0]: $!\n"
		if @_ and -e $_[0] and not unlink $_[0];
}

sub create_dir
{
	die "can't create $_[0]: $!\n"
		if @_ and not -d $_[0] and not mkdir $_[0];
}

sub unlink_dir
{
	die "can't delete $_[0]: $!\n"
		if @_ and -e $_[0] and not rmdir $_[0];
}

sub get_file_times
{
	die "usage" unless @_;

	my @s = stat $_[0];

	die "can't stat $_[0]:$!\n"
		unless @s;

	return @s[9, 10];
}

#-----------------------------------------------

# File
{
	my $test_file_name = 'test_file_name';

	{
		create_file $test_file_name;

		my ($mtime1, $ctime1) = get_file_times $test_file_name;

		sleep 2;

		file->new($test_file_name)->touch;

		my ($mtime2, $ctime2) = get_file_times $test_file_name;

		ok(($mtime1 < $mtime2 and $ctime1 < $ctime2));

		ok($mtime2 == $ctime2);
	}

	{
		unlink_file $test_file_name;
	
		file->new($test_file_name)->touch;

		my ($mtime2, $ctime2) = get_file_times $test_file_name;

		ok($mtime2 and $ctime2);
	}

	{
		my $data = "data";

		create_file $test_file_name, $data;

		my $f = file->new($test_file_name);

		$f->touch;

		ok($f->contents eq $data); # :)
	}

	unlink_file $test_file_name;
}


# Dir
{
	my $test_dir_name = 'test_dir_name';

	{
		create_dir $test_dir_name;

		my ($mtime1, $ctime1) = get_file_times $test_dir_name;
	
		sleep 2;

		dir->new($test_dir_name)->touch;
		
		my ($mtime2, $ctime2) = get_file_times $test_dir_name;

		ok(($mtime1 < $mtime2 and $ctime1 < $ctime2));

		ok($mtime2 == $ctime2);
	}

	{
		unlink_dir $test_dir_name;

		dir->new($test_dir_name)->touch;
		
		my ($mtime2, $ctime2) = get_file_times $test_dir_name;

		ok($mtime2 and $ctime2);
	}

	unlink_dir $test_dir_name;
}

# Generic
{
	{
		my $test_file_name = 'test_file_name';

		create_file $test_file_name;

		my ($mtime1, $ctime1) = get_file_times $test_file_name;

		sleep 2;
		
		IO::Easy->new($test_file_name)->touch;

		my ($mtime2, $ctime2) = get_file_times $test_file_name;

		ok(($mtime1 < $mtime2 and $ctime1 < $ctime2));

		ok($mtime2 == $ctime2);

		unlink_file $test_file_name;
	}

	{
		my $test_dir_name = 'test_dir_name';

		create_dir $test_dir_name;

		my ($mtime1, $ctime1) = get_file_times $test_dir_name;

		sleep 2;
		
		IO::Easy->new($test_dir_name)->touch;

		my ($mtime2, $ctime2) = get_file_times $test_dir_name;

		ok(($mtime1 < $mtime2 and $ctime1 < $ctime2));

		ok($mtime2 == $ctime2);

		unlink_dir $test_dir_name;
	}
}
