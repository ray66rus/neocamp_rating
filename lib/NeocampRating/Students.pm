package NeocampRating::Students;
use Mojo::Base 'Mojolicious::Controller';

use FindBin;

use constant PAGE_SIZE => 3;

sub paged {
	my $self = shift;

	my $params = $self->_get_current_params;

	my $resultset = $self->db->resultset('Student')->search(undef, {
		order_by => { "-$params->{order_direction}" => $params->{order_by} },
		rows => PAGE_SIZE,
		page => $params->{page}
	});

	my @students = $resultset->all;
	my $pager = $resultset->pager;

	return $self->render('students/paged',
		students => [@students],
		pager => {
			current_page => $pager->current_page,
			first_entry => $pager->first,
			last_page => $pager->last_page
		}
	);
}

sub _get_current_params {
	my $self = shift;

	my $order_by = defined($self->param('sort_by')) ?
		$self->param('sort_by') :
		$self->session('sort_by') || 'rating';
	my $order_key_name = $order_by . '_order';
	my $order_direction = defined($self->param($order_key_name)) ?
		$self->param($order_key_name) :
		$self->session($order_key_name) || 'desc';
	my $page = $self->param('page') || $self->session('page') || 1;

	$self->session($order_key_name => $order_direction);
	$self->session(sort_by => $order_by);
	$self->session(page => $page);

	return {
		order_by => $order_by,
		order_direction => $order_direction,
		page => $page,
	}
}

sub all {
	my $self = shift;

	my $params = $self->_get_current_params;

	my @students = $self->db->resultset('Student')->search(undef, {
		order_by => { "-$params->{order_direction}" => $params->{order_by} },
	});

	return $self->render('students/all',
		students => [@students],
		pager => {
			first_entry => 1,
		}
	);
}

sub save_ratings {
	my $self = shift;

	my @students_ids = grep /^student_\d+/, $self->param;
	my @error_msg = ();
	for my $student_id (@students_ids) {
		(my $db_id = $student_id) =~ s/^student_//;
		my $student_record = $self->db->resultset('Student')->search({id => $db_id});
		my $student = $student_record->single;
		if(!$student) {
			push @error_msg, "Can't find student with id $db_id";
			next;
		}
		my $rating_input = $self->param($student_id);
		my $rating_addition = 0;
		if($rating_input =~ /^[\s\d\+\-]+$/) {
			$rating_addition = eval $rating_input;
			if($@) {
				$rating_addition = 0;
				push @error_msg, "Wrong input data for student " . $student->name . qq|: "$rating_input"|;
			}
			$student_record->update({rating => $student->rating + $rating_addition});
		} else {
			push @error_msg, "Wrong input data for student " . $student->name . qq|: "$rating_input"|;
		}
	}
	if(@error_msg) {
		$self->flash(message => join("\n", @error_msg), message_type => 'error');
	} else {
		$self->flash(message => 'Ratings saved', message_type => 'success');
	}
	return $self->redirect_to($self->req->headers->referrer);
}

sub del {
	my $self = shift;

	my $id = $self->stash('id');

	my $student_rec = $self->db->resultset('Student')->search({id => $id});
	my $student = $student_rec->single;
	if(!$student) {
		$self->flash(message => "Can't find student with id $id", message_type => 'error');
		return $self->redirect_to($self->req->headers->referrer);
	}

	$self->flash(message => 'Student "' . $student->name . "' (" . $student->pid . ") deleted", message_type => 'success');
	$student_rec->delete_all;

	return $self->redirect_to($self->req->headers->referrer);
}

sub add {
	my $self = shift;
	return $self->render('students/edit_form', student => $self->db->resultset('Student')->new_result({id => ''}), referer => $self->req->headers->referrer);
}

sub edit {
	my $self = shift;
	my $options = shift;

	my $id = $self->stash('id');

	my $student_rec = $self->db->resultset('Student')->search({id => $id});
	my $student = $student_rec->single;
	if(!$student) {
		$self->flash(message => "Can't find student with id $id", message_type => 'error');
		return $self->redirect_to($self->req->headers->referrer);
	}

	return $self->render('students/edit_form', student => $student, referer => $self->req->headers->referrer);
}

sub save {
	my $self = shift;

	my %updated_vals = (
		id => $self->param('id'),
		pid => $self->param('pid'),
		name => $self->param('name'),
		rating => $self->param('rating')
	);
	$updated_vals{img} = $self->param('img_file')->filename
		if $self->param('img_file')->filename;

	my $is_new_user = ($updated_vals{id} eq '') ? 1 : 0;

	if($updated_vals{pid} eq '') {
		$self->stash(message => "ID field can't be empty", message_type => 'error');
		my $student = $self->db->resultset('Student')->new_result(\%updated_vals);
		return $self->render('students/edit_form', student => $student, referer => $self->param('referer'));
	}

	my $student = $self->db->resultset('Student')->search({pid => $updated_vals{pid}})->single;
	if($student and ($updated_vals{id} eq '' or $student->id ne $updated_vals{id})) {
		$self->stash(message => "User with personal id $updated_vals{pid} already exists", message_type => 'error');
		$student = $self->db->resultset('Student')->new_result(\%updated_vals);
		return $self->render('students/edit_form', student => $student, referer => $self->param('referer'));
	}

	if(!$self->_load_avatar) {
		$student = $self->db->resultset('Student')->new_result(\%updated_vals);
		return $self->render('students/edit_form', student => $student, referer => $self->param('referer'));
	}

	if($is_new_user) {
		delete $updated_vals{id};
		$self->db->resultset('Student')->create(\%updated_vals);
		$self->flash(message => qq|User "$updated_vals{name}" ($updated_vals{pid}) added|, message_type => 'success');
	} else {
		my $student_rec = $self->db->resultset('Student')->search({id => $updated_vals{id}});
		my $student = $student_rec->single; 
		if(!$student) {
			$self->flash(message => "Can't find student with id $updated_vals{id}", message_type => 'error');
			return $self->redirect_to($self->param('referer'));
		}
		if($updated_vals{img}) {
			unlink(($ENV{DB_FILE_PATH} || $FinBin::Bin) . '/../public/img/avatars/' . $student->img);
		} else {
			delete $updated_vals{img};
		}
		$student_rec->update(\%updated_vals);
		$self->flash(message => qq|User "$updated_vals{name}" ($updated_vals{id}) updated|, message_type => 'success');
	}

	return $self->redirect_to($self->param('referer'));
}

sub _load_avatar {
	my $self = shift;
	my $filedata = $self->req->upload('img_file');

	if(!$filedata) {
		$self->stash(message => 'File is not available', message_type => 'error');
		return 0;
	}

	if($self->req->is_limit_exceeded) {
		$self->stash(message => 'File is too big', message_type => 'error');
		return 0;
	}

	if($filedata->filename eq '') {
		$self->stash(message => 'Filename must not be empty', message_type => 'error');
		return 0;
	}

	$filedata->move_to(($ENV{DB_FILE_PATH} || $FinBin::Bin) . '/../public/img/avatars/' . $filedata->filename);

	return 1;
}

1;
