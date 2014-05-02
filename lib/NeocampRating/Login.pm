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
	
	if(!$self->users->check($user_id, $pass)) {
		$self->flash(message => "Wrong user name or password");
		return $self->redirect_to('login')
	}

	$self->session(user => $user_id);
	$self->flash(message => "Admin access granted");
	$self->redirect_to("protected");
}

sub logged_in {
	my $self = shift;
	return 1
		if $self->session('user');
	$self->redirect_to('students');
	return undef;
}

sub logout {
	my $self = shift;
	$self->session(expires => 1);
	$self->redirect_to('students');
}

1;
