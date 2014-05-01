package NeocampRating::Login;
use Mojo::Base 'Mojolicious::Controller';

sub login_form {
	my $self = shift;
	return $self->render;
}

sub login {
	my $self = shift;

	my $user_id = $self->param('user') || '';
	my $pass = $self->param('pass') || '';
	return $self->render
		unless $self->users->check($user_id, $pass);

	$self->session(user => $user_id);
	$self->flash(message => "Admin access granted");
	$self->redirect_to("protected");
}

sub logged_in {
	my $self = shift;
	return 1
		if $self->session('user');
	$self->redirect_to('rating');
	return undef;
}

sub logout {
	my $self = shift;
	$self->session(expires => 1);
	$self->redirect_to('rating');
}

1;
