package IO::Easy::Dir;

use strict;

use IO::Easy;
use base qw(IO::Easy);

use File::Spec;
my $FS = 'File::Spec';

sub create {
	my $self = shift;
	my @path = @_;
	
	my $path = $self->{path};
	if (scalar @path) { # create @path into received directory
		$path = File::Spec->catdir ($path, @path);
	}
	
	my @dirs = File::Spec->splitdir ($path);
    
    foreach my $depth (0 .. scalar @dirs - 1) {
		my $dir = File::Spec->join(map {$dirs[$_]} 0..$depth);
		mkdir $dir
			unless -d $dir;
    }

}

sub type {
	return 'dir';
}

sub items {
	my $self   = shift;
	my $filter = shift || '';
	my $is_regexp = shift || 0;
	
	my $path = $self->{path};
	
	unless ($is_regexp) {
		$filter = join '', '\.', $filter, '$';
	}
	
	opendir (DH, $path) || die "can't open $path: $!";
	my @files = ();
	foreach my $file_name (readdir (DH)) {
		next if $file_name =~ /^\.+$/;
		
		next if $filter ne '\.$' and $file_name !~ /$filter/i;
		
		my $file = $self->append ($file_name);
		
		next unless -e $file;
		
		push @files, $file->attach_interface;
	}
	closedir (DH);
	
	return @files;
}

sub rm_tree {
	my $self = shift;
	
	my @files = $self->items;
	foreach my $file (@files) {
		my $path = $file->{path};
		unlink $path
			if -f $path;
		$file->rm_tree
			if -d $path;
	}
	
	rmdir $self->{path};
}

sub scan_tree {
	my $self = shift;
	my $handler = shift;
	
	my $path = $self->{path};
	
	opendir (DH, $path) || die "can't open $path: $!";
	
	my @files;
	
	foreach my $file_name (readdir (DH)) {
		next if $file_name eq $FS->curdir or $file_name eq $FS->updir; # omit . ..
		
		my $file = $self->append ($file_name)->attach_interface;
		
		push @files, $file
			if &$handler ($file) and $file->type eq 'dir';
		
	}
	closedir (DH);
	
	foreach my $file (@files) {
		if ($file->type eq 'dir') {
			$file->scan_tree ($handler);
		} elsif ($file->type eq 'file') {
			
		}
	}
}

sub copy_children {
	my $self = shift;
	my $target = shift;
	my $handler = shift;
	
	$self->scan_tree (sub {
		my $file = shift;
		
		my $path = $file->rel_path ($self->{path});
		
		if (ref $handler eq 'CODE') {
			next unless &$handler ($file);
		}
		
		if ($file->type eq 'dir') {
			$target->create ($path);
			return 1;
		}
		
		$target->append ($path)->as_file->store (
			$file->contents
		);
	});
}

sub copy_node {
	my $self = shift;
	my $target = shift;
	
	$target->create ($self->name);
	
	$self->scan_tree (sub {
		my $file = shift;
		
		my $path = $file->rel_path ($self->updir->{path});
		
		if ($file->type eq 'dir') {
			$target->create ($path);
			return 1;
		}
		
		$target->append ($path)->as_file->store (
			$file->contents
		);
	});
}


1;