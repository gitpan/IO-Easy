package IO::Easy::File;

use Class::Easy;

use Encode qw(decode encode perlio_ok is_utf8);

use Fcntl ':seek';

use File::Spec;
our $FS = 'File::Spec';

use IO::Easy;
use base qw(IO::Easy);

use IO::Dir;

our $PART = 1 << 15;
our $ENC  = '';

our $IRS;

if ( $^O =~ /win32/i || $^O =~ /vms/i ) {
	$IRS = "\015\012" ;
} elsif ( $^O =~ /mac/i ) {
	$IRS = "\015" ;
} else {
	$IRS = "\012" ;
}

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
	
	my $fh;
	open ($fh, "<$io_layer", $self->{path})
		|| die "cannot open file $self->{path}: $!";
	
	my $contents;
	
	my $part = $self->part;
	my $buff;
	
	while (read ($fh, $buff, $part)) {
		$contents .= $buff;
	}
	
	close ($fh);
	
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
	
	my $fh;
	open ($fh, ">$io_layer", $self->{path})
		|| die "cannot open file $self->{path}: $!";
	
	print $fh $contents
		if defined $contents;
	
	close $fh;
	
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
	
	while (read(IN, $buff, 8 * 1 << 10)) {
		print OUT $buff;
	}
	
	close IN;
	close OUT;
	
	unlink $from_file;
	
	$self->{path} = $to_file;
	
}

sub string_reader {
	my $self = shift;
	my $sub  = shift;
	my %params = @_;
	
	# because we can't seek in characters
	my $fh;
	open ($fh, '<:raw', $self->{path}) or return; 

	my $seek_pos = 0;
	if ($params{reverse}) {
		if (seek ($fh, 0, SEEK_END)) {
			$seek_pos = tell ($fh);
		} else {
			return;
		}
	}
	
	my $buffer_size = $self->part;
	
	my $remains = '';
	my $buffer;
	my $read_cnt = 0;
	
	my $c = 10;
	
	if ($params{reverse}) {
		do {
			$seek_pos -= $buffer_size;
			$seek_pos = 0
				if $seek_pos < 0;

			seek ($fh, $seek_pos, SEEK_SET);
			$read_cnt = read ($fh, $buffer, $buffer_size);

			my @lines = split $IRS, $buffer . 'aaa';
			
			if ($lines[$#lines] eq 'aaa') {
				$lines[$#lines] = '';
			} else {
				$lines[$#lines] =~ s/aaa$//s;
			}
			
			$lines[$#lines] = $lines[$#lines] . $remains;
			$remains = shift @lines;
			
			for (my $i = $#lines; $i >= 0; $i--) {
				&$sub ($lines[$i]);
			}
			
		} while $seek_pos > 0;
	} else {
		do {
			# seek ($fh, $seek_pos, SEEK_SET);
			$read_cnt = read ($fh, $buffer, $buffer_size);
			
			$seek_pos += $buffer_size;
			
			my @lines = split $IRS, $buffer . 'aaa';
			
			if ($lines[$#lines] eq 'aaa') {
				$lines[$#lines] = '';
			} else {
				$lines[$#lines] =~ s/aaa$//s;
			}
			
			$lines[0] = $remains . $lines[0];
			$remains = pop @lines;
			
			foreach my $line (@lines) {
				&$sub ($line);
			}
			
		} while $read_cnt == $buffer_size;
		
	}
	
	&$sub ($remains);

	#	@{$lines_ref} = ( $self->{'sep_is_regex'} ) ?
	#		$text =~ /(.*?$self->{'rec_sep'}|.+)/gs :
	#		$text =~ /(.*?\Q$self->{'rec_sep'}\E|.+)/gs ;

}

sub __data__files {
	
	my ($caller) = caller; 
	
	$caller ||= '';
	
	no strict 'refs';
	
	local $/;
	my $buf;
	eval "\$buf = <${caller}::DATA>";
	
	my @files = split /[\s\n\r\t]*#[#\s\n\r\t]+/, $buf;
	
	my $counter  = 0;
	my $response = {};
	
	while ($counter < scalar @files) {
		
		if ($files[$counter] =~ /^IO::Easy(?:::File)?\s+(\S+)/) {
			my $file_name = $1;
			if (defined $files[$counter + 1] && $files[$counter + 1] =~ /^IO::Easy(?:::File)?\s+/) {
				$response->{$file_name} = '';
			} else {
				$response->{$file_name} = $files[$counter + 1] || '';
				$counter++;
			}
		}
		
		$counter++;
	}
	
	return $response;
}

1;
=head1 NAME

IO::Easy::File - IO::Easy child class for operations with files.

=head1 METHODS

=head2 contents, path, extension, dir_path

	my $io = IO::Easy->new ('.');
	my $file = $io->append('example.txt')->as_file;
	print $file->contents;		# prints file content
	print $file->path;			# prints file path, in this example it's './example.txt'
	print $file->extension;		# file extension, in this example it's 'txt'
	print $file->dir_path;		# parent directory, './'

=cut

=head2 store, store_if_empty

IO::Easy::File has 2 methods for saving file: store and store_if_empty

	my $io = IO::Easy->new ('.');
	my $file = $io->append('example.txt')->as_file;
	my $content = "Some text goes here";

	$file->store($content);   			# saves the variable $content to file

	$file->store_if_empty($content);	# saves the variable $content to file, only 
										# if there's no such a file existing.		


=cut

=head2 create

creates new directory

	my $io = IO::Easy->new ('.');
	my $dir = $io->append('data')->as_dir; 	# appends 'data' to $io and returns 
											#the new object; blesses into directory object.
	$dir->create;							# creates directory './data/'

or

	$io->as_dir->create ('data');

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
