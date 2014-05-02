package NeocampRating::Students;
use Mojo::Base 'Mojolicious::Controller';

sub main {
	my $self = shift;
	my @students = $self->db->resultset('Student')->search(undef, { order_by => { -desc => 'rating' }});
	return $self->render('students/main', students => [@students]);
}

sub save_ratings {
	my $self = shift;
	$self->flash(message => 'Ratings saved');
	my @students_ids = grep /^student_\d+/, $self->param;
	for my $student_id (@students_ids) {
		(my $db_id = $student_id) =~ s/^student_//;
		my $rating = $self->param($student_id);
		my $student = $self->db->resultset('Student')->search({id => $db_id})->update({rating => $rating});
	}
	return $self->redirect_to('students');
}

1;
