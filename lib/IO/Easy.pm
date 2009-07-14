package IO::Easy;

use Class::Easy;

use vars qw($VERSION);
$VERSION = '0.05';

use File::Spec;

my $stat_methods = [qw(dev inode mode nlink uid gid rdev size atime mtime ctime blksize blocks)];

foreach my $i (0 .. $#$stat_methods) {
	has ($stat_methods->[$i], default => sub {
		my $self = shift;
		my $stat = $self->stat;

		return $stat->[$i];
	});
}

use overload
	'""'  => 'path',
	'cmp' => '_compare';

our $FS = 'File::Spec';

sub new {
	my $class = shift;
	my $path  = shift;
	my $args  = shift || {};
	
	my $self = bless {%$args, path => $path}, $class;
	
	my $initialized = $self;
	$initialized = $self->_init
		if $self->can ('_init');
	
	return $initialized;
}

sub attach_interface {
	my $self = shift;
	
	if (-f $self->{path}) {
		return $self->as_file;
	} elsif (-d $self->{path}) {
		return $self->as_dir;
	}
	
	
}

sub name {
	my $self = shift;
	
	my $result = ($FS->splitpath ($self->{path}))[2];
	
	return $result;
}

sub as_file {
	my $self = shift;
	
	my $file_object = {%$self};
	try_to_use ('IO::Easy::File');
	bless $file_object, 'IO::Easy::File';
}

sub as_dir {
	my $self = shift;
	
	my $file_object = {%$self};
	try_to_use ('IO::Easy::Dir');
	bless $file_object, 'IO::Easy::Dir';
}


sub append {
	my $self = shift;
	
	my $appended = File::Spec->join ($self->{path}, @_);
	return IO::Easy->new ($appended);
}

sub append_in_place {
	my $self = shift;
	
	my $appended = File::Spec->join ($self->{path}, @_);
	$self->{path} = $appended;
	
	return $self;
}

sub path {
	my $self = shift;
	
	return $self->{path};
}

sub _compare { # for overload only
	my $self = shift;
	my $value = shift;
	return $self->{path} cmp $value;
}

# we need ability to create abstract file object without any 
# filesystem checks, but when call any method, assigned to 
# concrete class, we must create another object and call this method

sub touch {
	my $self = shift;
	
	my $subclass = __PACKAGE__ . '::File';
	# require $subclass;
	
	bless $self, $subclass;
	
	$self->_init;
	
	$self->store;
}

sub abs_path {
	my $self = shift;
	
	my $path = $self->{path};
	
	return $FS->rel2abs ($path);
	
}

sub rel_path {
	my $self = shift;
	my $relative = shift;
	
	my $path = $self->{path};
	
	return $FS->abs2rel ($path, $relative);
}

sub path_components {
	my $self = shift;
	my $relative = shift;
	
	my $path = $self->{path};
	
	if ($relative) {
		$path = $FS->abs2rel ($path, $relative);
	}
	
	return $FS->splitdir ($path);
	
}

sub stat {
	my $self  = shift;
	my $renew = 0;
	
	if ($renew || ! exists $self->{stat}) {
		$self->{stat} = [stat $self->{path}];
	}
	
	return $self->{stat};
}

sub modified {
	my $self = shift;
	
	my $stat = $self->stat;
	return $stat->[9];
}

sub size {
	my $self = shift;
	
	my $stat = $self->stat;
	return $stat->[9];
}

sub updir {
	my $self = shift;
	
	my @chunks = $FS->splitdir ($self->path);
	pop @chunks;
	
	my $updir = $FS->catdir (@chunks);
	
	try_to_use ('IO::Easy::Dir');
	return IO::Easy::Dir->new ($updir);
}

1;

=head1 NAME

IO::Easy - is easy to use class for operations with filesystem objects.

=head1 ABSTRACT

We wanted to provide Perl with the interface for file system objects
with the simplicity similar to shell. The following operations can be
used as an example: operations for recursive creation (mkdir -p) and
removing (rm -rf), touching file.

IO::Easy transparently processes file system paths independently
from operating system with help of File::Spec module and does not
require a lot of additional modules from CPAN.

For better understanding of IO::Easy processing principles you should
keep in mind that it operates with "Path Context". "Path Context" means
that for any path in any file system IO::Easy takes path parts which are
between path separators, but doesn't include path separators themselves,
and tries to fetch the path in the current system from these path parts.
This way it can substitute different path separators from system to system
(as long as they may differ depending on operating system, this also
includes drive specification e.g. for Windows) and doesn't depend on
some system specifics of paths representation.

=head1 SYNOPSIS

	use IO::Easy;

	my $io = IO::Easy->new ('.');

	# file object "./example.txt" for unix
	my $file = $io->append ('example.txt')->as_file;

	my $content = "Some text goes here!";

	$file->store ($content); 

=head1 METHODS

=head2 new

Creates new IO::Easy object, takes path as parameter. IO::Easy object
for abstract file system path. For operating with typed objects there
were 2 additional modules created:
	IO::Easy::File
	IO::Easy::Dir

You can use method attach_interface for automatic object conversion
for existing filesystem object or force type by using methods
as_file or as_dir.

=cut

=head2 name

return current filesystem object name

=cut

=head2 as_file, as_dir, attach_interface

TODO

=cut

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
