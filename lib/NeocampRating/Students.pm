package NeocampRating::Students;
use Mojo::Base 'Mojolicious::Controller';

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
	$self->flash(message => 'Ratings saved', message_type => 'success');
	my @students_ids = grep /^student_\d+/, $self->param;
	for my $student_id (@students_ids) {
		(my $db_id = $student_id) =~ s/^student_//;
		my $rating = $self->param($student_id);
		my $student = $self->db->resultset('Student')->search({id => $db_id})->update({rating => $rating});
	}
	return $self->redirect_to($self->req->headers->referrer);
}

1;
