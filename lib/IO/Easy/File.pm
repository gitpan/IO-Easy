package IO::Easy::File;

use strict;

use IO::Easy;
use base qw(IO::Easy);

use Encode qw(decode encode perlio_ok is_utf8);

use File::Spec;

our $FS = 'File::Spec';

use IO::Dir;

our $PART = 1024*1024;
our $ENC  = '';

sub _init {
	my $self = shift;
	
	return $self->_init_layer;
	
}

sub type {
	return 'file';
}

sub enc {
	my $self = shift;
	my $enc  = shift;
	
	return $self->{enc} || $ENC
		unless $enc;
	
	$self->{enc} = $enc;
	return $self->_init_layer;
}

sub _init_layer {
	my $self = shift;
	
	my $enc = $self->enc;
	
	if (!defined $enc or $enc eq '') {
		# binary reading
		$self->{layer} = ':raw';
	} else {
		my $enc_ok = perlio_ok ($enc);
		unless ($enc_ok) {
			warn "selected encoding ($enc) are not perlio savvy";
			return undef;
		}
		$self->{layer} = ":encoding($enc)";
	}
	return $self;
}

sub store_if_empty {
	my $self = shift;
	return if -e $self;
	
	$self->store (@_);
}

sub layer {
	my $self = shift;
	my $layer = shift;
	
	$self->_init_layer;
	
	return $self->{layer}
		unless $layer;
	
	my $old_layer = $self->{layer};
	$self->{layer} = $layer;
	
	return $old_layer;
}

sub part {
	my $self = shift;
	my $part = shift;
	
	return $self->{part} || $PART
		unless $part;
	
	$self->{part} = $part;
}

sub file_name {
	my $self = shift;
	
	my ($vol, $dir, $file) = $FS->splitpath ($self->{path});
	return $file;
}

sub base_name {
	my $self = shift;
	
	my $file_name = $self->file_name;
	
	my $base_name = ($file_name =~ /(.*?)(?:\.[^\.]+)?$/)[0];
	
	return $base_name;
}

sub extension {
	my $self = shift;
	
	my $file_name = $self->file_name;
	
	my $base_name = ($file_name =~ /(?:.*?)(?:\.([^\.]+))?$/)[0];
	
	return $base_name;
}

sub dir_path {
	my $self = shift;
	
	my ($drive, $path) = $FS->splitpath ($self->{path});
	my $result = $path;
	$result = $FS->join ($drive, $path)
		if $FS->file_name_is_absolute ($self->{path});
	
	return IO::Easy::Dir->new($result);
}

sub contents {
	my $self = shift;
	
	my $enc = $self->enc;
	
	my $io_layer = $self->layer;
	
	open (FH, "<$io_layer", $self->{path})
		|| die "cannot open file $self->{path}: $!";
	
	my $contents;
	
	my $part = $self->part;
	my $buff;
	
	while (read (FH, $buff, $part)) {
		$contents .= $buff;
	}
	
	close (FH);
	
	return $contents;
}

sub store {
	my $self = shift;
	my $contents = shift;
	
	my $enc = $self->enc;
	
	my $change_layer;
	
	if (defined $enc and $enc ne '' and ! is_utf8 ($contents)) {
		$change_layer = $self->layer (':raw');
	}
	
	my $io_layer = $self->layer;
	
	open (FH, ">$io_layer", $self->{path})
		|| die "cannot open file $self->{path}: $!";
	
	print FH $contents
		if defined $contents;
	
	close FH;
	
	if (defined $change_layer and $change_layer ne '') {
		$self->layer ($change_layer);
	}
	
	return 1;
}

sub move {
	my $self = shift;
	my $to = shift;
	
	# rename function is highly dependent on os, don't rely on it
	my $from_file = $self->path;
	my $to_file = $to;
	$to_file = $to->path
		if ref $to eq 'IO::Easy::File';
	
	$to_file = $FS->join($to->path, $self->file_name)
		if ref $to eq 'IO::Easy::Dir';
	
	$to = IO::Easy::File->new ($to_file);
	
	$to->dir_path->create; # create dir if necessary
	
	print 'move from: ', $from_file, ' to: ', $to_file, "\n";
	
	unless (open (IN, $from_file)) {
		warn "can't open $from_file: $!";
		return;
	}
	unless (open (OUT, '>', $to_file)) {
		warn "can't open $to_file: $!";
		return;
	}

	binmode(IN);
	binmode(OUT);
	
	my $buff;
	
	while (read(IN, $buff, 8 * 2**10)) {
		print OUT $buff;
	}
	
	close IN;
	close OUT;
	
	unlink $from_file;
	
	$self->{path} = $to_file;
	
}

1;