package NeocampRating::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub parse_and_save_csv {
	my $self = shift;

	my $filedata = $self->req->upload('csv_file');

	if(!$filedata) {
		$self->flash(message => 'File is not available', message_type => 'error');
		return $self->redirect_to('/load_csv');
	}

	if($self->req->is_limit_exceeded) {
		$self->flash(message => 'File is too big', message_type => 'error');
		return $self->redirect_to('/load_csv');
	}

	if($filedata->filename eq '') {
		$self->flash(message => 'Filename must not be empty', message_type => 'error');
		return $self->redirect_to('/load_csv');
	}

	my $errors = $self->_parse_and_save_filedata($filedata);

	if(@$errors) {
		$self->flash(message => join("\n", @$errors), message_type => 'error');
	} else {
		$self->flash(message => 'File loaded', message_type => 'success');
	}
	return $self->redirect_to('all');
}

sub _parse_and_save_filedata {
	my $self = shift;
	my $filedata = shift;

	my @errs = ();

	my $csv_data = $filedata->slurp;
	my @records = split("\n", $csv_data);
	for my $record(@records) {
		my $err = $self->_update_or_create_record($record);
		push @errs, $err
			if $err;
	}
	return \@errs;
}

sub _update_or_create_record {
	my $self = shift;
	my $record = shift;

	my ($id, $rating, $name, $pic_file_name) = split(',', $record);
	$name = ''
		unless defined($name);
	$pic_file_name = ''
		unless defined($pic_file_name);
	for($id, $rating, $name, $pic_file_name) {
		s/^\s*//; s/\s*$//;
	}
	my $student_rec = $self->db->resultset('Student')->search({pid => $id});
	my $student = $student_rec->single;

	if(!$student) {
		return "Student with personal id $id doesn't exist"
			unless($name);
		$self->db->resultset('Student')->create({pid => $id, name => $name, img => $pic_file_name, rating => $rating});
	} else {
		my %update_vals = (rating => $rating);
		$update_vals{name} = $name
			if $name;
		$update_vals{img} = $pic_file_name
			if $pic_file_name;
		$student_rec->update(\%update_vals);
	}
	return '';
}

1;
