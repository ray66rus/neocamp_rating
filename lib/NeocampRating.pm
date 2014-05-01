package NeocampRating;
use Mojo::Base 'Mojolicious';

use NCRUser;


# This method will run once at server start
sub startup {
	my $self = shift;

	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');

	$self->secrets(['bang bang and production']);
	$self->helper(users => sub { state $user = NCRUser->new });

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->any('/')->to('rating#main')->name('rating');
	$r->get('/login')->to('login#login_form');
	$r->post('/login')->to('login#login');
	my $logged_in = $r->under->to('login#logged_in');
	$logged_in->get('/protected')->to('login#protected');
	$r->get('/logout')->to('login#logout');
}

1;
